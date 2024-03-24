Shader "ENTI/P3_Hologram"
{
    Properties
    {
        _Color("Color", Color) = (1,1,1,1)
        _Power("Power", float) = 1.0
        [Enum(UnityEngine.Rendering.BlendMode)]
        _SrcFactor("Src Factor", float) = 5
        [Enum(UnityEngine.Rendering.BlendMode)]
        _DstFactor("Dst Factor", float) = 10
        [Enum(UnityEngine.Rendering.BlendOp)]
        _Opp("Operation", float) = 0
    }
        SubShader
        {
            Tags { "RenderType" = "Transparent" "Queue" = "Transparent" }
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
                    half3 normal : NORMAL;

                };

                struct v2f
                {
                    float4 vertex : SV_POSITION;
                    half3 normal : NORMAL;
                    half3 viewdir : TEXCOORD0;
                };

                fixed4 _Color;
                float _Power;

                v2f vert(appdata v)
                {
                    v2f o;
                    o.vertex = UnityObjectToClipPos(v.vertex);
                    o.normal = normalize(UnityObjectToWorldNormal(v.normal));

                    //Manera 1
                    o.viewdir = normalize(WorldSpaceViewDir(v.vertex));
                    //Manera 2
                    //o.viewdir = normalize(mul((float3x3) unity_CameraToWorld, float3(0,0,1)));
                    return o;
                }

                fixed4 frag(v2f i) : SV_Target
                {
                    fixed4 col;
                //col.xyz = i.normal;
                //col.xyz = -i.viewdir;
                float fresnel = saturate(dot(i.normal, i.viewdir));
                fresnel = saturate(1 - fresnel);
                fresnel = pow(fresnel, _Power);
                //col.xyz = fresnel.xxx;
                fixed4 fresnelColor = fresnel * _Color;
                col = fresnelColor;


                return col;
            }
            ENDCG
        }
        }
}
