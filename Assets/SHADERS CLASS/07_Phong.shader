Shader"ENTI/07_Phong"
{
    Properties
    {
        [Space(10)]
        [Header(Diffuse)]
        _Attenuation ("Attenuation", range(0.001,5)) = 1.0

        [Space(10)]
        [Header(Ambient)]
        _Color ("Ambient Color", Color) = (1,1,1,1)
        _AmbientIntensity ("Ambient Intensity", range(0.001,5)) = 1.0

        [Space(10)]
        [Header(Specular)]
        _SpecColor ("Specular Color", Color) = (1,1,1,1)
        _SpecPower ("Specular Power", range(0.001,20)) = 1.0
        _SpecIntensity ("Specular Intensity", range(1,5)) = 1.0
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
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float4 col : COLOR;
            };

            fixed4 _Color, _SpecColor;
            float _Attenuation, _AmbientIntensity,_SpecPower,_SpecIntensity;

            uniform float4 _LightColor0;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);     
    
                float3 viewDirection = normalize(WorldSpaceViewDir(v.vertex));
                //Get normal direction
                float3 normalDirection = normalize(mul(float4(v.normal,0.0), unity_WorldToObject).xyz);
                //Get light direction
                float3 lightDirection = normalize(_WorldSpaceLightPos0.xyz);
                //Diffuse reflection
                float3 diffuseReflection = dot(normalDirection,lightDirection);    
                diffuseReflection = max(0.0, diffuseReflection) * _Attenuation;
                
                //Specular reflection
                float3 x = reflect(-lightDirection, normalDirection);
                float3 specularReflection = dot(x, viewDirection);
                specularReflection = pow(max(0.0, specularReflection), _SpecPower) * _SpecIntensity;
                specularReflection *= diffuseReflection;
                specularReflection *= _SpecColor.rgb;
                
                float3 lightFinal = diffuseReflection * _LightColor0.rgb;
    
                //Use default ambient
                //lightFinal += UNITY_LIGHTMODEL_AMBIENT.rgb;
    
                lightFinal += (_Color.rgb * _AmbientIntensity);
                lightFinal += specularReflection;
    
                //Visualize
                o.col = float4(specularReflection, 1.0);
    
    
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {                
                return i.col;
            }
            ENDCG
        }
    }
}
