Shader"ENTI/P2_Terrain"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _HeightMap("Heightmap", 2D) = "white" {}
        _Heatmap("Heatmap", 2D) = "white" {}
        _HeightMultiplier("Height Multiplier", float) = 1.0
        _Center ("Center", Vector) = (-6, 0, -16, 0)
        _RadiusSpeed("Radius Speed", float) = 0.5
        _MaxRadius("Max Radius", float) = 5.0
        _RadiusColor ("Radius Color", Color) = (1,0,0,1)
        _RadiusWidth ("Radius Width", range(0.15,0.65)) = 0.25



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
                float3 worldPos : TEXCOORD1; 
            };

            sampler2D _HeightMap;
            float4 _HeightMap_ST;
            sampler2D _Heatmap;
            float4 _Heatmap_ST;
            fixed4 _Color;
            float _HeightMultiplier;
            float4 _Center;
            float _RadiusSpeed;
            float _MaxRadius;
            fixed4 _RadiusColor;
            float _RadiusWidth;


            v2f vert(appdata v)
            {
                v2f o;


                o.vertex = UnityObjectToClipPos(v.vertex);
                
                float4 worldPos = mul(unity_ObjectToWorld, v.vertex);	            
               
	            o.uv = TRANSFORM_TEX(worldPos.xz, _HeightMap);
                
                float2 local_tex_Height = tex2Dlod(_HeightMap, float4(o.uv, 0, 0));
                float l_Height = local_tex_Height.y * -_HeightMultiplier;
                
                o.uv = float2(v.uv.x, local_tex_Height.y);

                o.vertex.y = o.vertex.y + l_Height;

                //o.uv = v.uv;
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
               float2 uvs = i.uv;
                fixed4 col = tex2D(_Heatmap, uvs);

                // Calculate distance from fragment to _Center point
                float distanceToCenter = distance(i.worldPos.xz, _Center.xz);

                // Check if the fragment is within the specified radius
                if (distanceToCenter < _RadiusWidth)
                {
                    col = _RadiusColor; // Set the color to _RadiusColor if within the radius
                }

                return col;
            }
            ENDCG
        }
    }
}