Shader"ENTI/02_Vertex_Unlit"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex("Main Tex", 2D) = "WHITE" {}
        _Scale("Scale",float) = 1.0
        _TilingOffset ("Tiling and offset",vector) = (1.0,1.0,1.0,1.0)
        _Displacement ("Displacement", float) = 1.0
        _DispTex("Displacement Texture", 2D) = "WHITE" {}
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
                //float2 uv2 : TEXCOORD1;
                float3 normal : NORMAL;
                //float4 tangent : TANGENT;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                //fixed4 color : COLOR;
                float4 dispTex : TEXCOORD1;
            };

            sampler2D _MainTex, _DispTex;
            float4 _MainTex_ST;
            float4 _DispTex_ST;
            float _Scale;
            float4 _TilingOffset;
            fixed4 _Color;
            float _Displacement;

            v2f vert (appdata v)
            {
                v2f o;
    
                float2 local_uv = v.uv;
                local_uv *= _TilingOffset.xy;
                local_uv += _TilingOffset.zw;
    
                o.uv = TRANSFORM_TEX(local_uv, _MainTex);
    
                v.vertex *= _Scale;
    
                float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                half4 displacetex = tex2Dlod(_DispTex, float4(worldPos.x * _Time.x, worldPos.y, 0, 0));
                v.vertex.xyz += _Displacement * v.normal * displacetex;
    
                o.dispTex = displacetex;
                o.vertex = UnityObjectToClipPos(v.vertex); 
                /*
                //NORMAL
                //o.color.xyz = v.normal * 0.5 + 0.5;
    
                //TANGENT
                //o.color = v.tangent * 0.5 + 0.5;
    
                //BITANGENT
                //float3 bitangent = cross(v.normal, v.tangent);
                //o.color.xyz = bitangent * 0.5 + 0.5;
                
                //UV
                //o.color = float4(v.uv2.xy, 0, 0);
                //o.color.w = 1.0;
                */
    
                //DISPLACEMENT
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {        
                half4 col = tex2D(_MainTex,i.uv);
                col += (i.dispTex * _Color);
                return col;
            }
            ENDCG
        }
    }
}
