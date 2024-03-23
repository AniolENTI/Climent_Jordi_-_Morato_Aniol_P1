Shader"ENTI/08_Celshade"
{
    Properties
    {

        _MainTex("Main Texture", 2D) = "white" {}
        [Space(1)]
        [Header(Diffuse)]
        _Attenuation ("Attenuation", range(0.001,5)) = 1.0

        [Space(1)]
        [Header(Ambient)]
        _Color ("Ambient Color", Color) = (1,1,1,1)
        _AmbientIntensity ("Ambient Intensity", range(0.001,5)) = 1.0

        [Space(1)]
        [Header(Specular)]
        _SpecColor ("Specular Color", Color) = (1,1,1,1)
        _SpecPower ("Specular Power", range(0.001,20)) = 1.0
        _SpecIntensity ("Specular Intensity", range(1,5)) = 1.0

        [Space(1)]
        [Header(Celshade)]
        _CelTreshold ("Celshade Treshold", range(0,1)) = 1.0
        _ShadowColor ("Shadow Color", Color) = (1,1,1,1)
        _ShadowIntensity ("Shadow Intensity", range(0,1)) = 1.0

    }
    SubShader
    {
        Tags { "LightMode"="ForwardBase" }

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
float _Attenuation, _AmbientIntensity, _SpecPower, _SpecIntensity, _CelTreshold, _ShadowIntensity;

            uniform float4 _LightColor0;

            v2f vert (appdata v)
            {
                v2f o;
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.vertex = UnityObjectToClipPos(v.vertex); 
                o.normal = normalize(mul(float4(v.normal, 0.0), unity_WorldToObject).xyz);
                o.viewdir = normalize(WorldSpaceViewDir(v.vertex));
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            { 
    
                float3 viewDirection = i.viewdir;
                //Get normal direction
                float3 normalDirection = i.normal;
                //Get light direction
                float3 lightDirection = normalize(_WorldSpaceLightPos0.xyz);
                //Diffuse reflection
                float3 diffuseReflection = dot(normalDirection, lightDirection);
                diffuseReflection = max(0.0, diffuseReflection) * _Attenuation;
                
                //celshade
                fixed light = step(_CelTreshold, diffuseReflection.r);
                light = lerp(_ShadowIntensity, fixed(1), light);
                fixed3 lightCol = lerp(_ShadowColor.rgb, _LightColor0, light);
    
                //Specular reflection
                float3 x = reflect(-lightDirection, normalDirection);
                float3 specularReflection = dot(x, viewDirection);
                specularReflection = pow(max(0.0, specularReflection), _SpecPower) * _SpecIntensity;
    
                //---BLINN-PHONG
                float3 halfDirection = normalize(lightDirection + viewDirection);
                float3 specAngle = max(0.0, dot(viewDirection, normalDirection));
                specularReflection = pow(specAngle, _SpecPower) * _SpecIntensity;
                //---
    
                specularReflection *= diffuseReflection;
                specularReflection *= _SpecColor.rgb;
                
                float3 lightFinal = lightCol;
                lightFinal += lightCol;
                //Use default ambient
                //lightFinal += UNITY_LIGHTMODEL_AMBIENT.rgb;
                //Use custom ambient
                lightFinal += (_Color.rgb * _AmbientIntensity);
                lightFinal += specularReflection;
    
                //Visualize
                i.col = float4(lightFinal, 1.0);
    
                return i.col;
            }
            ENDCG
        }
    }
}
