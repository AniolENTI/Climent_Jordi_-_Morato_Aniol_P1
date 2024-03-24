Shader "ENTI/P5_PBRMoss"
{
    Properties
    {
        [Header(Albedo)]
        _MainTex("Rock Texture", 2D) = "white" {}
        _TopTex("Grass Texture", 2D) = "black" {}
        _Sharpness("Sharpness", Range(0.001, 64)) = 1.0

        [Header(Roughness)]
        _RoughnessMap("Roughness Map", 2D) = "black" {}

        [Header(Normal)]
        _NormalMap("Normal Map", 2D) = "white" {}
        _NormalStrength("Normal Strength", Range(0, 1)) = 1.0

        [Header(PBR Properties)]
        _Exposure("Exposure", Range(0.1, 10)) = 1.0
        _FresnelPower("Fresnel Power", Range(0.1, 10)) = 5.0
        _FresnelColor("Fresnel Color", Color) = (0.5, 0.5, 0.5, 1.0)
    }

        SubShader
        {
            Tags { "RenderType" = "Opaque" }

            Pass
            {
                CGPROGRAM
                #pragma vertex vert
                #pragma fragment frag

                #include "UnityCG.cginc"

                struct appdata
                {
                    float4 vertex : POSITION;
                    float3 normal : NORMAL;
                    float2 uv : TEXCOORD0;
                    float4 tangent : TANGENT;
                };

                struct v2f
                {
                    float2 uv : TEXCOORD0;
                    float3 worldPos : TEXCOORD1;
                    float3 normal : TEXCOORD2;
                    float3 tangent : TEXCOORD3;
                    float3 binormal : TEXCOORD4;
                    float3 viewDir : TEXCOORD5;
                    UNITY_VERTEX_INPUT_INSTANCE_ID
                };

                sampler2D _MainTex;
                float4 _MainTex_ST;
                sampler2D _TopTex;
                float4 _TopTex_ST;
                sampler2D _RoughnessMap;
                sampler2D _NormalMap;
                float4 _NormalMap_ST;
                float _Sharpness;
                float _Exposure;
                float _FresnelPower;
                float4 _FresnelColor;

                v2f vert(appdata v)
                {
                    v2f o;
                    o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                    o.normal = mul(unity_ObjectToWorld, float4(v.normal, 0.0)).xyz;
                    o.viewDir = normalize(_WorldSpaceCameraPos.xyz - o.worldPos);
                    o.uv = v.uv;
                    o.tangent = mul(unity_ObjectToWorld, float4(v.tangent.xyz, 0.0)).xyz;
                    o.binormal = cross(o.normal, o.tangent) * v.tangent.w;
                    return o;
                }

                fixed4 frag(v2f i) : SV_Target
                {
                    // Triplanar mapping
                    float3 albedo = float3(1, 1, 1); // Default albedo color
                    float2 uv_front = i.worldPos.yz * _MainTex_ST.xy + _MainTex_ST.zw;
                    float2 uv_top = i.worldPos.xz * _TopTex_ST.xy + _TopTex_ST.zw;
                    float2 uv_side = i.worldPos.xy * _MainTex_ST.xy + _MainTex_ST.zw;

                    fixed4 col_front = tex2D(_MainTex, uv_front);
                    fixed4 col_top = tex2D(_TopTex, uv_top);
                    fixed4 col_side = tex2D(_MainTex, uv_side);

                    if (i.normal.y > 0)
                    {
                        albedo = col_top.rgb;
                    }
                    else
                    {
                        albedo = lerp(col_side.rgb, col_front.rgb, 0.5); // Adjust blend factor as needed
                    }

                    // Roughness and normal mapping (only on rock)
                    float roughness = tex2D(_RoughnessMap, i.uv).r;
                    float3 normalMap = UnpackNormal(tex2D(_NormalMap, i.uv));
                    normalMap = normalize(normalMap * 2.0 - 1.0);
                    float3 normal = normalize(i.normal * (1 - _Sharpness) + normalMap * _Sharpness);

                    // PBR lighting calculations
                    float3 viewDir = normalize(i.viewDir);
                    float3 lightDir = normalize(_WorldSpaceLightPos0 - i.worldPos);

                    float NdotL = max(0.0, dot(normal, lightDir));
                    float3 diffuse = albedo * NdotL;

                    float3 halfwayDir = normalize(viewDir + lightDir);
                    float NdotH = max(0.0, dot(normal, halfwayDir));
                    float3 specular = pow(NdotH, _FresnelPower) * _FresnelColor.rgb;

                    float3 lighting = _Exposure * (diffuse + specular);

                    return float4(lighting, 1.0);
                }
                ENDCG
            }
        }
}