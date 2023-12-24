Shader "Unlit/NewUnlitShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #define MAX_STEPS 100
            #define MAX_DIST 100
            #define SURF_DIST 1e-3
            #define FRACT_STEPS 20
            #define PI 3.14159

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 ro : TEXCOORD1;
                float3 hitPos : TEXCOORD2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _t =0;
            float Range;//This is a scaler for external controls
            float3 TimeTrans = float3(1,1,1);
            float3 TimeRot = 0.0;
            float3 cp1;//This is control point 1. This will be attached to one of the hands
            int3 Mirror = int3(1,1,1);
            int Fractal = 1;
            float3 Trans = float3(0.5,1,1);
            float3 Rot = float3(1,0,0);;
            float3 Twist;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.ro = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos,1));//Mul by WorldToObject forces the render to be relative to the object
                o.hitPos = v.vertex;

                return o;
            }

            float3 mix (float x, float y, float a)
            {
                return x*(1-a)+y*a;
            }

            float2x2 rotate(float a)
            {
                float c = cos(a),
                s = sin(a);
                return float2x2(c, -s, s, c);
            }   

            float3 grid (float3 p)
            {
                p = fmod(p+3., 6.)-3.;
                return p;
            }

            //float3 hs(float3 c, float s){
            //    s*= 2.*PI;//This lets .0 to 1. be 0 to 360 rotation of the color wheel
            //    float3 m=float3(cos(s),s=sin(s)*.5774,-s);
            //    return c*float3x3(m+=(1.-m.x)/3.,m.zxy,m.yzx);
            //}

            float opSmoothUnion( float d1, float d2, float k ){
                float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
                return mix( d2, d1, h ) - k*h*(1.0-h);
            }

            float opSubtraction( float d1, float d2){
                return max(-d1,d2);
            }

            float opXor(float d1, float d2 )
            {
                return max(min(d1,d2),-max(d1,d2));
            }

            float3 spaceTransform(float3 p){
                //p.yz *= rotate(p.y*p.z*TwistY*sin(_t*0.25)); //Twist
                //p.x = rotate(sin(_t*0.5));
                //p.y = rotate(sin(_t*0.5));
                p.x += Trans.x;
                return p;
            }

            //float3 objectTransform(float3 p){
            //    p.xz *= rotate(p.y*TwistY*(20.*sin(_t*1.))); //Twist
            //    p.yx *= rotate(sin(_t*0.5));
            //    return p;
            //}

            //Shaping Functions
            float recSDF(float3 p, float rec){
                return length(max(abs(p) - rec, 0.));
            }

            float boxSDF( float3 p, float3 box ){
            float3 q = abs(p) - box;
            return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
            }
            
            float sphereSDF(float3 p, float sphere){
                return length(p)-sphere;
            }

            float3 fractal(float3 p){
                for (int i = 0; i < FRACT_STEPS ; i++){
                    if(Mirror.x == 1) p.x = abs(p.x); //Mirror X
                    if(Mirror.y == 1) p.y = abs(p.y); //Mirror Y
                    if(Mirror.z == 1) p.z = abs(p.z); //Mirror Z

                    p.x -= Trans.x
                    +cp1.x*Range
                    +TimeTrans.x*sin(_t*0.2);
                    p.y -= Trans.y+cp1.y*Range
                    +cp1.y*Range
                    +TimeTrans.y*cos(_t*0.1);;
                    p.z -= Trans.z;

                    p.x *= rotate(Rot.x+sin(_t*0.2)*TimeRot.x);
                    p.y *= rotate(Rot.y+sin(_t*0.2)*TimeRot.y);
                    p.z *= rotate(Rot.z+cos(_t*0.1)*TimeRot.z);
                    p.y *= rotate(p.y*Twist.y); //Twist

                    return p;
                }
            }

            float GetDist (float3 p)
            {
                float d = 1.;
                if (Fractal == 1) 
                {
                    p = float3(10,10,10);
                    //p = fractal(p);
                }
                d = sphereSDF(p, 0.15);
                d = recSDF(p, float3(0.25,0.5,0.5));

                return d;
            }
            
            float Raymarch (float3 ro, float3 rd) 
            {
                float dO = 0;
                float dS;
                for (int i=0; i < MAX_STEPS; i++)
                {
                    float3 p = ro + dO * rd;
                    dS = GetDist(p);
                    dO += dS;
                    if(dS<SURF_DIST || dO>MAX_DIST) 
                    {
                        break;
                    }
                }

                return dO;
            }

            float3 GetNormal(float3 p)
            {
                float2 e = float2(1e-2, 0);
                float3 n = GetDist(p) - float3(
                GetDist(p-e.xyy),
                GetDist(p-e.yxy),
                GetDist(p-e.yyx)
                );
                return normalize(n);
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float2 uv = i.uv-.5;
                float3 ro = i.ro;
                float3 rd = normalize(i.hitPos-ro);

                float d = Raymarch(ro, rd);
                fixed4 col = 0;
                if(d > MAX_DIST)
                {
                    discard;
                } else {
                    col = 1;
                    float3 p = ro + rd * d;
                    float3 n = GetNormal(p);
                    col.rgb = n;
                }
                //col.rgb = rd;
                //col = tex2D(_MainTex, i.uv);
                return col;
            }
            ENDCG
        }
    }
}
