Shader "NullShaders/RayMarch"
{

    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _t ("Time", Float) = 0
        _txRange ("Transform Range", Float) = 1 //This is a scaler for external controls
        _rotRange ("Rotate Range", Float) = 0.0087 //This is a scaler for external controls
        
        _TimeTrans ("Time Transform", Vector) = (1,1,1)
        _TimeRot ("Time Rotate", Vector) = (1,1,1)
        _lhp ("Left Hand Position", Vector) = (1,1,1)
        _lhr ("Left Hand Rotation", Vector) = (1,1,1)
        _rhp ("Right Hand Position", Vector) = (1,1,1)
        _rhr ("Right Hand Rotation", Vector) = (1,1,1)
        _handPosDiff ("Hand Postition diffrence", Vector) = (1,1,1)
        _Mirror ("Mirror Enable", Vector) = (1,1,1)
        _Fractal ("Fractal Enable", Int) = 1
        _Trans ("Transform", Vector) = (0.0,0.0,.0)
        _Rot ("Rotate", Vector) = (0,0,0)
        _Twist ("Twist", Vector) = (0,0,0)
        _CubeSize ("Cube Size", Vector) = (0.1,0.1,0.1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            Cull Off
            CGPROGRAM
            //#include "Packages/com.meta.xr.depthapi.urp/Shaders/EnvironmentOcclusionURP.hlsl"
            #pragma vertex vert
            #pragma fragment frag
            // DepthAPI Environment Occlusion
            //#pragma multi_compile _ HARD_OCCLUSION SOFT_OCCLUSION

            #include "UnityCG.cginc"
            #define MAX_STEPS 20
            #define MAX_DIST 4
            #define SURF_DIST 1e-3
            #define FRACT_STEPS 5
            #define PI 3.14159



            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;

                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 ro : TEXCOORD1;
                float3 hitPos : TEXCOORD2;

                UNITY_VERTEX_OUTPUT_STEREO
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _t;
            float _txRange;//This is a scaler for external controls
            float _rotRange;//This is a scaler for external controls
            float3 _TimeTrans;
            float3 _TimeRot;
            float3 _lhp;//This is control point 1. This will be attached to one of the hands
            float3 _lhr;
            float3 _handPosDiff;
            int3 _Mirror;
            int _Fractal;
            float3 _Trans;
            float3 _Rot;
            float3 _Twist;
            float3 _CubeSize;
            float3 _CubeControlTransform;
            float3 _CubeControlRotation;

            v2f vert (appdata v)
            {
                v2f o;

                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

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

            float3 hs(float3 c, float s){
                s*= 2.*PI;//This lets .0 to 1. be 0 to 360 rotation of the color wheel
                float3 m=float3(cos(s),s=sin(s)*.5774,-s);
                return mul(c,float3x3(m+=(1.-m.x)/3.,m.zxy,m.yzx));
            }

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

            float3 objectRotate(float3 p, float angle){
                    p.xy = mul(p.xy,angle);
                    p.xz =  mul(p.xz,angle);
                    p.yz =  mul(p.yz,angle);
                    return p;
            }

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
                    +_lhp.x
                    *_txRange
                    //+_TimeTrans.x*sin(_t*0.2)
                    ;
                    p.y -= _Trans.y
                    +_lhp.y
                    *_txRange
                    //+_TimeTrans.y*cos(_t*0.1)
                    ;
                    p.z -= _Trans.z
                    +_lhp.z
                    *_txRange
                    ;

                    p.xy = mul(p.xy,rotate(_Rot.x
                    +_lhr.y*_rotRange
                    ));
                    p.xz =  mul(p.xz,rotate(_Rot.y
                    +_lhr.x*_rotRange
                    ));
                    p.yz =  mul(p.yz,rotate(_Rot.z
                    +_lhr.z*_rotRange
                    ));
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
                float rec1 = recSDF(p+_CubeControlTransform, _CubeSize);
                //float rec1 = recSDF(p, _CubeSize);


                //d = min(d, rec1);
                d = opSmoothUnion(d, rec1, 1.);
                //d = opSmoothUnion(d, sphere1, .125);


                return d;
            }
            
            float3 Raymarch (float3 ro, float3 rd) 
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

                float3 d = Raymarch(ro, rd);
                fixed4 col = 0;
                if(d.x > MAX_DIST)
                {
                    discard;
                } else {
                    col = 0;
                    float3 p = ro + rd * d.x;
                    float3 n = GetNormal(p);

                    col.r = d.r*.25;
                    col.g = d.g*.0125;
                    col.b = d.b;
                    col.rgb += n*.25;
                    col.a = 1.;
                    col.rgb = hs(col, .4);
                }
                //col.rgb = rd;
                //col = tex2D(_MainTex, i.uv);
                return col;
            }
            ENDCG
        }
    }
}
