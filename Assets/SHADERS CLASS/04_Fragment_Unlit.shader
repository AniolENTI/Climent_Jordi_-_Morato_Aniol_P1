Shader"ENTI/04_Fragment_Unlit"
{
    Properties
    {
        _Color1 ("Color1", Color) = (1,1,1,1)
        _Color2 ("Color2", Color) = (1,1,1,1)
        _Blend("_Blend Value", Range(0,1)) = 1.0

        _MainTex("Main Texture", 2D) = "white" {}
        _SecondTex("Second Texture", 2D) = "white" {}
        _ThirdTex("Third Texture", 2D) = "white" {}

        _BlendTex("Blend Texture", 2D) = "white" {}

        

    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }
        Blend SrcAlpha OneMinusSrcAlpha
        Zwrite Off

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
    
            };

            sampler2D _MainTex;
            fixed4 _MainTex_ST;
            sampler2D _SecondTex;
            fixed4 _SecondTex_ST;
            sampler2D _ThirdTex;
            fixed4 _ThirdTex_ST;

            sampler2D _BlendTex;
            fixed4 _BlendTex_ST;

            fixed4 _Color1;
            fixed4 _Color2;
            float _Blend;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);              
                o.uv = v.uv;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {         
                fixed4 col;
                //1 Blending
                col = _Color1 + _Color2 * _Blend;
    
                //2  Interpolation
                col = _Color1 * (1 - _Blend) + _Color2 * _Blend;
                col = lerp(_Color1, _Color2, _Blend); 
    
                //3 Textures
                //Calculate UV coordinates
                float2 main_uv = TRANSFORM_TEX(i.uv, _MainTex);
                float2 second_uv = TRANSFORM_TEX(i.uv, _SecondTex);
                float2 third_uv = TRANSFORM_TEX(i.uv, _ThirdTex);
                //Read colors form textures
                fixed4 main_color = tex2D(_MainTex, main_uv);
                fixed4 second_color = tex2D(_SecondTex, second_uv);
                fixed4 third_color = tex2D(_ThirdTex, third_uv);
                //Interpolate
    
                float2 blend_uv = TRANSFORM_TEX(i.uv, _BlendTex);
                fixed4 blend_color = tex2D(_BlendTex, blend_uv);
    
                //col = lerp(main_color, second_color, blend_color.r);
                col = _Color1;
                col = lerp(col, main_color, blend_color.r);
                col = lerp(col, second_color, blend_color.g);
                col = lerp(col, third_color, blend_color.b);
    
                //Sin
                float sin_value = sin(_Time.y);
                sin_value = saturate(sin_value); //Clamps the value (0,1)
                sin_value = frac(sin_value); //return fractional (decimal) = (0.0,0.9)
                col = lerp(_Color1, _Color2, sin_value);
    
                
                
                return col;
            }
            ENDCG
        }
    }
}
