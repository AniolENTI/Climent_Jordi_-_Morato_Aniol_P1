Shader "ENTI/P3_Hologram"
{
    Properties
    {
        _Color("Color", Color) = (1,1,1,1)

        [Space(1)]
        [Header(Fresnel)]

        [HDR] _FresnelColor("Fresnel Color", Color) = (1,1,0,1)
        _Power("Power", float) = 1.0
        [Enum(UnityEngine.Rendering.BlendMode)]
        _SrcFactor("Src Factor", float) = 5
        [Enum(UnityEngine.Rendering.BlendMode)]
        _DstFactor("Dst Factor", float) = 10
        [Enum(UnityEngine.Rendering.BlendOp)]
        _Opp("Operation", float) = 0

        [Space(1)]
        [Header(Scrolling Bars)]
        _BarIntensity("Bar Intensity", Float) = 1
        _AnimationIntensity("Animation Intensity", Float) = 1
        _Rotator("Rotator", Range(0,1)) = 1
    }
        SubShader
        {
            Tags { "RenderType" = "Transparent" "Queue" = "Transparent"  }
            Blend[_SrcFactor][_DstFactor]
            BlendOp[_Opp]
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
                    float2 uv : TEXCOORD0;
                    half3 normal : NORMAL;
                };

                struct v2f
                {
                    //float2 uv : TEXCOORD0;
                    float4 vertex : SV_POSITION;
                    half3 normal : NORMAL;
                    half3 viewdir : TEXCOORD0;
                };

                fixed4 _Color;

                //Fresnel
                fixed4 _FresnelColor;
                float _Power;

                //Scrolling Bars
                float _BarIntensity, _AnimationIntensity, _Rotator;

                v2f vert(appdata v)
                {
                    v2f o;
                    o.vertex = UnityObjectToClipPos(v.vertex);
                    o.normal = normalize(UnityObjectToWorldNormal(v.normal));
                    o.viewdir = normalize(WorldSpaceViewDir(v.vertex));
                    return o;
                }

                fixed4 frag(v2f i) : SV_Target
                {
                    fixed4 col;
                    
                    //FRESNEL
                    float fresnel = saturate(dot(i.normal, i.viewdir));
                    fresnel = saturate(1 - fresnel);
                    fresnel = pow(fresnel, _Power);
                    fixed4 fresnelColor = fresnel * _Color;
                    col = fresnelColor * _FresnelColor;

                    //SCROLLING BARS
                    //float rotate = lerp(i.uv.x, i.uv.y, _Rotator);
                    //float anim = _AnimationIntensity * _Time.y;
                    //float barEffect = sin(rotate * _BarIntensity + anim) * 0.5 + 0.5;
                    //return fixed4(barEffect, 0, 0, 1);

                    return col;
                }
                ENDCG
            }   
        }
}
