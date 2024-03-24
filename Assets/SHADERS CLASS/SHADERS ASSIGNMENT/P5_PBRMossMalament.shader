Shader "ENTI/P5_PBRMossMalament"
{
    Properties
    {
        [Header(Unity Standard Properties)]
        _ShadowStrength("Unity Shadow Strength", Range(0,1)) = 0.75
        _DMetalProperty("Unity Diffuse Metal Property", Range(0,1)) = 1
        _Exposure("Unity Exposure", Range(1,10)) = 1
        _FresnelPower("Unity Fresnel Power", Range(0.001,10)) = 5
        _FresnelColor("Unity Fresnel Color", Color) = (0.5, 0.5, 0.5, 1.0)

        [Space(1)]
        [Header(Albedo)]
        _MainTex("Rock Texture", 2D) = "white" {}
        _TopTex("Grass Texture", 2D) = "black" {}
        _Sharpness("Sharpness", Range(0.001,64)) = 1.0

        [Space(1)]
        [Header(Roughness)]
        _RoughnessMap("Roughness Map", 2D) = "black" {}
        _Roughness("Roughness", Range(0,1)) = 0

        [Space(1)]
        [Header(Normal)]
        _NormalMap("Normal Map", 2D) = "white" {}
        _NormalStrength("Normal Strength", Range(0,1)) = 1.0

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

                #define _PI 3.14159265359

                struct appdata
                {
                    float4 vertex : POSITION;
                    float3 normal : NORMAL;
                    float2 uv : TEXCOORD0;
                    float4 tangent : TANGENT;
                };

                struct v2f
                {
                    float4 vertex : SV_POSITION;
                    float3 normal : NORMAL;
                    float2 uv : TEXCOORD0;
                    float3 tangent : TEXCOORD1;
                    float3 binormal : TEXCOORD2;
                    float4 col : COLOR;
                    float3 worldPos : TEXCOORD3;
                };

                fixed4 _Color;
                sampler2D _MainTex;
                float4 _MainTex_ST;
                sampler2D _TopTex;
                float4 _TopTex_ST;
                float _Sharpness;
                sampler2D _RoughnessMap;
                float4 _RoughnessMap_ST;
                sampler2D _NormalMap;
                float4 _NormalMap_ST;

                float _ShadowStrength, _DMetalProperty, _Exposure, _FresnelPower;
                float _Roughness, _NormalStrength;

                //----------------------[[[[[ FUNCTIONS ]]]]]------------------------------------------------           
                //1. Schlick Fresnel Functions---------------------------------------------------------------
                float SchlickFresnel(float i)
                {
                    float x = clamp(1.0 - i, 0.0, 1.0);
                    float x2 = x * x;
                    return x2 * x2 * x;
                }

                float3 FresnelLerp(float3 x, float3 y, float d)
                {
                    float t = SchlickFresnel(d);
                    return lerp(x, y, t);
                }

                float3 SchlickFresnelFunction(float3 SpecularColor, float LdotH)
                {
                    return SpecularColor + (1 - SpecularColor) * SchlickFresnel(LdotH);
                }

                //2. Normal Incidence Reflection Calculation-------------------------------------------------
                float F0(float NdotL, float NdotV, float LdotH, float roughness)
                {
                    // Diffuse fresnel
                    float FresnelLight = SchlickFresnel(NdotL);
                    float FresnelView = SchlickFresnel(NdotV);
                    float FresnelDiffuse90 = 0.5 + 2.0 * LdotH * LdotH * roughness;
                    float MixFLight = (FresnelDiffuse90 * FresnelLight + 1.0 * (1.0 - FresnelLight));
                    float MixFView = (FresnelDiffuse90 * FresnelView + 1.0 * (1.0 - FresnelView));
                    return MixFLight * MixFView;
                }

                //3. Normal Distribution Functions-----------------------------------------------------------
                float GGXNormalDistribution(float roughness, float NdotH)
                {
                    float roughnessSqr = roughness * roughness;
                    float NdotHSqr = NdotH * NdotH;
                    float TanNdotHSqr = (1 - NdotHSqr) / NdotHSqr;
                    float sqrResult = roughness / (NdotHSqr * (roughnessSqr + TanNdotHSqr));
                    return (1.0 / _PI) * (sqrResult * sqrResult);
                }

                //4. Geometric Shadowing Functions-----------------------------------------------------------
                float GGXGeometricShadowingFunction(float NdotL, float NdotV, float roughness)
                {
                    float roughnessSqr = roughness * roughness;
                    float NdotLSqr = NdotL * NdotL;
                    float NdotVSqr = NdotV * NdotV;
                    float SmithL = (2 * NdotL) / (NdotL + sqrt(roughnessSqr + (1 - roughnessSqr) * NdotLSqr));
                    float SmithV = (2 * NdotV) / (NdotV + sqrt(roughnessSqr + (1 - roughnessSqr) * NdotVSqr));
                    float Gs = (SmithL * SmithV);
                    return Gs;
                }
                //--------------------------------------------------------------------------------------------

                v2f vert(appdata v)
                {
                    v2f o;
                    o.vertex = UnityObjectToClipPos(v.vertex);
                    o.uv = v.uv;
                    float4 worldPos = mul(unity_ObjectToWorld, v.vertex);
                    o.worldPos = worldPos.xyz;
                    o.vertex = UnityObjectToClipPos(v.vertex);
                    o.normal = normalize(mul(float4(v.normal, 0.0), unity_WorldToObject).xyz);
                    o.tangent = normalize(mul(unity_ObjectToWorld, float4(v.tangent.xyz, 0.0)).xyz);
                    o.binormal = normalize(cross(o.normal, o.tangent) * v.tangent.w);

                    return o;
                }

                fixed4 frag(v2f i) : SV_Target
                {
                    //calculate uv position for 3 projections
                    float2 uv_front = TRANSFORM_TEX(i.worldPos.yz, _MainTex);
                    float2 uv_top = TRANSFORM_TEX(i.worldPos.xz, _MainTex);
                    float2 uv_side = TRANSFORM_TEX(i.worldPos.xy, _MainTex);

                    //read textures at uv position of 3 projections
                    fixed4 col_front = tex2D(_MainTex, uv_front);
                    fixed4 col_top = tex2D(_MainTex, uv_top);
                    fixed4 col_side = tex2D(_MainTex, uv_side);

                    if (i.normal.y > 0)
                    {
                        uv_top = TRANSFORM_TEX(i.worldPos.xz, _TopTex);
                        col_top = tex2D(_TopTex, uv_top);

                    }

                    //create weights through normals
                    float3 weights = i.normal;
                    weights = abs(weights);
                    weights = pow(weights, _Sharpness);
                    weights = weights / (weights.x + weights.y + weights.z);

                    //apply the weights to the textures
                    col_front *= weights.x;
                    col_top *= weights.y;
                    col_side *= weights.z;

                    fixed4 col = col_front + col_top + col_side;

                    //visualize the weights
                    //col.rgb = weights;

                    return col;
                }
                ENDCG
            }
        }
}
