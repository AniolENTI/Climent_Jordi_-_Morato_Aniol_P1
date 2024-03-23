Shader"ENTI/P1_Water"
{
    Properties
    {

        _Color ("Color", Color) = (1,1,1,1)        
        _MainTex ("Main Texture", 2D) = "white" {}
        _HeightMultiplier ("Height Multiplier", float) = 0.5
        _HeightBias ("Height Bias", range(0.001,1.0)) = 0.4
        _NoiseScale ("Noise Scale ", float) = 50
        _NoiseMovement ("Noise Movement", Vector) = (-0.2, 2, 0, 0)

        _FlowTex ("Flow Texture", 2D) = "black" {}
        _FlowMapMovement ("Flow Map Movement", Vector) = (1, -0.5, 0, 0)
        _TemperatureStrenght ("Temperature Strenght", range(0.001,10.0)) = 4
        
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;

            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;                
                float2 noise_uv : TEXCOORD1;   
            };

            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _HeightMultiplier;
            float _HeightBias;
            float _NoiseScale;
            float4 _NoiseMovement;

            sampler2D _FlowTex;
            float4 _FlowTex_ST;
            float4 _FlowMapMovement;
            float _TemperatureStrenght;

            float2 unity_gradientNoise_dir(float2 p)
            {
                p = p % 289;
                float x = (34 * p.x + 1) * p.x % 289 + p.y;
                x = (34 * x + 1) * x % 289;
                x = frac(x / 41) * 2 - 1;
                return normalize(float2(x - floor(x + 0.5), abs(x) - 0.5));
            }

            float unity_gradientNoise(float2 p)
            {
                float2 ip = floor(p);
                float2 fp = frac(p);
                float d00 = dot(unity_gradientNoise_dir(ip), fp);
                float d01 = dot(unity_gradientNoise_dir(ip + float2(0, 1)), fp - float2(0, 1));
                float d10 = dot(unity_gradientNoise_dir(ip + float2(1, 0)), fp - float2(1, 0));
                float d11 = dot(unity_gradientNoise_dir(ip + float2(1, 1)), fp - float2(1, 1));
                fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
                return lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x);
            }

            v2f vert (appdata v)
            {                
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);          
                o.uv = TRANSFORM_TEX(v.uv, _MainTex); 

                
                o.uv += _FlowMapMovement.xy * _Time.x;
                o.noise_uv = TRANSFORM_TEX(v.uv, _FlowTex);


                //float2 NoiseUV = float2((v.uv.xy + _Time * ))
               
                float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                float2 displacetex = ((o.uv * (_NoiseMovement.x * _NoiseScale)) * _HeightBias) + _HeightMultiplier;

                
                v.vertex.xyz += unity_gradientNoise(displacetex);
    
                //o.dispTex = displacetex;
                o.vertex = UnityObjectToClipPos(v.vertex); 

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {            
                
                fixed4 noise = tex2D(_FlowTex, i.noise_uv);
                fixed2 disturb = noise.xy * 0.5 - 0.5;
    
                fixed4 col = tex2D(_MainTex, i.uv + disturb);
                fixed noisePulse = tex2D(_FlowTex, i.noise_uv + disturb).a;
    
                fixed4 temper = col * noisePulse * _TemperatureStrenght + (col * col - 0.1);
                col = temper * _Color;                
                col.a = 1.0;
    
                return col;
            }
            ENDCG
        }
    }
}
