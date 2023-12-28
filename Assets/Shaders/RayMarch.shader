Shader "Unlit/NewUnlitShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _t ("Time", Float) = 0
        _Range ("Range", Float) = 1 //This is a scaler for external controls
        
        _TimeTrans ("Time Transform", Vector) = (1,1,1)
        _TimeRot ("Time Rotate", Vector) = (1,1,1)
        _cp1 ("Control Point 1", Vector) = (1,1,1) //This is control point 1. This will be attached to one of the hands
        _Mirror ("Mirror Enable", Vector) = (1,1,1)
        _Fractal ("Fractal Enable", Int) = 1
        _Trans ("Transform", Vector) = (0.25,0.5,.25)
        _Rot ("Rotate", Vector) = (1,0,0)
        _Twist ("Twist", Vector) = (1,0,0)

    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            Cull Off
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #define MAX_STEPS 125
            #define MAX_DIST 100
            #define SURF_DIST 1e-3
            #define FRACT_STEPS 10
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
            float _t;
            float _Range;//This is a scaler for external controls
            float3 _TimeTrans;
            float3 _TimeRot;
            float3 _cp1;//This is control point 1. This will be attached to one of the hands
            int3 _Mirror;
            int _Fractal;
            float3 _Trans;
            float3 _Rot;
            float3 _Twist;

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
                float c = cos(a);
                float s = sin(a);
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
                //p.yz *= rotate(p.y*p.z*_Twist.y*sin(_t*0.25)); //Twist
                //p.x = rotate(sin(_t*0.5));
                //p.y = rotate(sin(_t*0.5));
                p.x += _Trans.x;
                return p;
            }

            //float3 objectTransform(float3 p){
            //    p.xz *= rotate(p.y*_Twist.y*(20.*sin(_t*1.))); //Twist
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

            float3 Fractalize(float3 p){
                for (int i = 0; i < FRACT_STEPS ; i++)
                {
                    if(_Mirror.x == 1) p.x = abs(p.x); //Mirror X
                    if(_Mirror.y == 1) p.y = abs(p.y); //Mirror Y
                    if(_Mirror.z == 1) p.z = abs(p.z); //Mirror Z
                    
                    p.x -= _Trans.x
                        //+_cp1.x*_Range
                    //    +_TimeTrans.x*sin(_t*0.2)
                    ;
                    p.y -= _Trans.y+_cp1.y*_Range
                    //    +_cp1.y*_Range
                    //    +_TimeTrans.y*cos(_t*0.1)
                    ;
                    p.z -= _Trans.z;

                    p.xy = mul(p.xy,rotate(_Rot.x));
                    p.xz =  mul(p.xz,rotate(_Rot.y));
                    p.yz =  mul(p.yz,rotate(_Rot.z));
                    p.yz =  mul(p.yz,rotate(p.y*_Twist.y)); //Twist


                }

                return p;
            }

            float GetDist (float3 p)
            {
                float d = 100.;
                if (_Fractal == 1)
                {
                    p = Fractalize(p);
                }
                float sphere1 = sphereSDF(p, 0.1);
                float rec1 = recSDF(p, float3(.125,.125,.125));

                //d = min(d, rec1);
                d = opSmoothUnion(d, rec1, 1.);
                d = opSmoothUnion(d, sphere1, .25);


                return d;
            }
            
            float Raymarch (float3 ro, float3 rd) 
            {
                float3 dO = 0; //x = distance ray has traveled, y = Iterations to hit, z = Closest distance to surface
                float dS;
                for (int i=0; i < MAX_STEPS; i++)
                {
                    float3 p = ro + dO.x * rd;
                    dS = GetDist(p);
                    dO.x += dS;
                    dO.z = min(dS, dO.z);
			        dO.y = float(i);
                    if(dS<SURF_DIST || dO.x>MAX_DIST) 
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
