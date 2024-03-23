Shader"ENTI/06_Dissolve"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex("Main Texture", 2D) = "white" {}
        _MaskTex("Mask Texture", 2D) = "white" {}
        _RevealValue("Reveal Value", Range(0,1)) = 1.0
        _Feather("Feather", float) = 1.0
        _NoiseScale("Noise Scale", float) = 1.0

    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }
        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float4 uv : TEXCOORD0;
    
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float4 uv : TEXCOORD0;
    
            };

            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;

            sampler2D _MaskTex;
            float4 _MaskTex_ST;

            float _RevealValue, _Feather, _NoiseScale;

            //NOISE FUNCTIONS-------------------------------------------------------------------------
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
            //NOISE FUNCTIONS-------------------------------------------------------------------------


            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);   
                o.uv = v.uv;
                o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
                o.uv.zw = TRANSFORM_TEX(v.uv, _MaskTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {                
                fixed4 col = tex2D(_MainTex, i.uv.xy);
                fixed4 mask = tex2D(_MaskTex, i.uv.zw);
                
                //float noise = unity_gradientNoise(i.uv.zw) * _NoiseScale; //El noise no va
    
                //1 Smooth Gradient Reveal
                float revealAmountSmooth = smoothstep(mask.r - _Feather, mask.r + _Feather, _RevealValue);
    
                //col = lerp(col, mask, revealAmountSmooth);
                //2 Dissolve with a color
                float revealTop = step(mask.r, _RevealValue + _Feather);
                float revealBot = step(mask.r, _RevealValue - _Feather);
                float Difference = revealTop - revealBot;
                fixed3 finalCol = lerp(col.rgb, _Color, Difference);
                
                return fixed4(finalCol.rgb, col.a * revealTop);
}
            ENDCG
        }
    }
}
