Shader "ENTI/P4_CelShade"
{
    Properties
    {
        _MainTex("Main Tex", 2D) = "white" {}
        _OutlineWidth("Outline Width", Range(0, 0.0005)) = 0.0001

        [Space(1)]
        [Header(Diffuse)]
        _Attenuation("Attenuation", Range(0.001,5)) = 1.0

        [Space(1)]
        [Header(Ambient)]
        _Color("Ambient Color", Color) = (1,1,1,1)
        _AmbientIntensity("Ambient Intensity", Range(0.001,5)) = 1.0

        [Space(1)]
        [Header(Specular)]
        _SpecColor("Specular Color", Color) = (1,1,1,1)
        _SpecPow("Specular Power", Range(0.001,20)) = 1.0
        _SpecIntensity("Specular Intensity", Range(1,5)) = 1.0

        [Space(1)]
        [Header(Celshade)]
        _CelThreshold("Celshade Threshold", Range(0,1)) = 1.0
        _ShadowColor("Shadow Color", Color) = (1,1,1,1)
        _ShadowIntensity("Shadow Intensity", Range(0,1)) = 1.0

    }
        SubShader
        {
            Tags { "LightMode" = "ForwardBase" }

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
                };

                struct v2f
                {
                    float4 vertex : SV_POSITION;
                    float3 normal : NORMAL;
                    float2 uv : TEXCOORD0;
                    float3 viewdir : TEXCOORD1;
                    float4 col : COLOR;
                };

                sampler2D _MainTex;
                float4 _MainTex_ST;
                fixed4 _Color, _SpecColor, _ShadowColor;
                float _Attenuation, _AmbientIntensity, _SpecPow, _SpecIntensity, _CelThreshold, _ShadowIntensity;

                // unity defined variables
                uniform float4 _LightColor0;

                v2f vert(appdata v)
                {
                    v2f o;
                    o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                    o.vertex = UnityObjectToClipPos(v.vertex);

                    o.normal = normalize(mul(float4(v.normal, 0.0), unity_WorldToObject).xyz);
                    o.viewdir = normalize(WorldSpaceViewDir(v.vertex));

                    return o;
                }

                float4 frag(v2f i) : SV_TARGET
                {
                    fixed4 col = tex2D(_MainTex, i.uv);

                    float3 viewDirection = i.viewdir;
                    //get normal direction
                    float3 normalDirection = i.normal;
                    //get light direction
                    float3 lightDirection = normalize(_WorldSpaceLightPos0.xyz);

                    //diffuse reflection
                    float3 diffuseReflection = dot(normalDirection, lightDirection);
                    diffuseReflection = max(0.0, diffuseReflection) * _Attenuation;

                    //celshade
                    fixed light = step(_CelThreshold, diffuseReflection.r);
                    light = lerp(_ShadowIntensity, fixed(1), light);
                    fixed3 lightCol = lerp(_ShadowColor.rgb, _LightColor0.rgb, light);

                    //specular reflection
                    float3 x = reflect(-lightDirection, normalDirection);
                    float3 specularReflection = dot(x, viewDirection);
                    specularReflection = pow(max(0.0, specularReflection), _SpecPow) * _SpecIntensity;
                    //---BLINN-PHONG
                    float3 halfDirection = normalize(lightDirection + viewDirection);
                    float specAngle = max(0.0, dot(halfDirection, normalDirection));
                    specularReflection = pow(specAngle, _SpecPow) * _SpecIntensity;
                    //---
                    specularReflection *= diffuseReflection;
                    specularReflection *= _SpecColor.rgb;

                    float3 lightFinal = lightCol * col;

                    //use default ambient
                    //lightFinal += UNITY_LIGHTMODEL_AMBIENT.rgb;
                    //use custom ambient
                    lightFinal += (_Color.rgb * _AmbientIntensity);
                    lightFinal += specularReflection;

                    //visualize
                    i.col = float4(lightFinal, 1.0);

                    return i.col;
                }
                ENDCG
            }

            Pass
            {
                    Cull Front
                    CGPROGRAM
                    #pragma vertex vert
                    #pragma fragment frag

                    #include "UnityCG.cginc"

                    struct appdata
                    {
                        float4 vertex : POSITION;
                        float3 normal : NORMAL;
                    };

                    struct v2f
                    {
                        float4 vertex : SV_POSITION;
                    };

                    fixed4 _Color;
                    float _OutlineWidth;

                    v2f vert(appdata v)
                    {
                        v2f o;
                        v.vertex.xyz += _OutlineWidth * v.normal;
                        o.vertex = UnityObjectToClipPos(v.vertex);
                        return o;
                    }

                    fixed4 frag(v2f i) : SV_Target
                    {
                        return _Color;
                    }
                    ENDCG
            }
        }
}