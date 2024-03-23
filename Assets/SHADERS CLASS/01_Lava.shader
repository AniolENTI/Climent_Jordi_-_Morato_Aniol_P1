Shader"ENTI/01_Lava"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Main Texture", 2D) = "white" {}
        _NoiseTex ("Noise Texture", 2D) = "black" {}
        _Flow1 ("Flow vector 1", Vector) = (1, 0, 0, 0)
        _Flow2 ("Flow vector 2", Vector) = (0.5, -0.5, 0, 0)

        _FlowAmount ("Flow Amount", float) = 1.0
        _FlowSpeed ("Flow Speed", float) = 1.0
        _MoveSpeed ("Move Speed", float) = 0.01
        _PulsePower ("Pulse Power", float) = 1.0
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
            sampler2D _NoiseTex;
            float4 _NoiseTex_ST;
            float4 _Flow1;
            float4 _Flow2;
            float4 _Flow3;

            float _FlowAmount;
            float _FlowSpeed;
            float _MoveSpeed;
            float _PulsePower;

            v2f vert (appdata v)
            {
                //1, texture
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);          
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
    
                //2. flow map
                o.uv += _Flow1.xy * _Time.x;
                o.noise_uv = TRANSFORM_TEX(v.uv, _NoiseTex);
                o.noise_uv += _Flow2.xy * _Time.x;
    
                //3. extra flow map
                float2 flowVector = tex2Dlod(_NoiseTex, float4(o.uv, 0, 0)).rg;
                o.uv += o.uv - flowVector * sin(_Time.y * _FlowSpeed) * _FlowAmount * _Time * (_MoveSpeed / 100);
    
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {            
                //float2 uv = i.uv;
                fixed4 noise = tex2D(_NoiseTex, i.noise_uv);
                fixed2 disturb = noise.xy * 0.5 - 0.5;
    
                fixed4 col = tex2D(_MainTex, i.uv + disturb);
                fixed noisePulse = tex2D(_NoiseTex, i.noise_uv + disturb).a;
    
                fixed4 temper = col * noisePulse * _PulsePower + (col * col - 0.1);
                col = temper;
                col.a = 1.0;
    
                return col;
            }
            ENDCG
        }
    }
}
