Shader "UI/OverlayGlassEffect"
{
    Properties
    {
        _Color ("Color", Color) = (1, 1, 1, 1)
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
        _Opacity ("Opacity", Range(0,1)) = 0.5
        _MainTex ("MainTex", 2D) = "white" {}
    }
    SubShader
    {
        Tags {"Queue"="Overlay" "IgnoreProjector"="True" "RenderType"="Transparent"}
        LOD 200

        Pass
        {
            // Use alpha blending for transparency
            Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct appdata_t
            {
                float4 vertex : POSITION;
                float2 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 texcoord : TEXCOORD0;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _Color;
            float _Glossiness;
            float _Metallic;
            float _Opacity;

            v2f vert(appdata_t v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                fixed4 texColor = tex2D(_MainTex, i.texcoord);
                fixed4 finalColor = _Color * texColor;

                // Apply opacity and blend with background
                finalColor.a *= _Opacity;

                return finalColor;
            }
            ENDCG
        }
    }
    FallBack "Transparent/Diffuse"
}