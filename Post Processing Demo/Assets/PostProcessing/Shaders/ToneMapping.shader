Shader "Hidden/ToneMapping"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
	}
	SubShader
	{
		// No culling or depth
		Cull Off ZWrite Off ZTest Always

		Pass
		{
			CGPROGRAM
			#pragma fragmentoption ARB_precision_hint_fastest
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 3.0
			#pragma multi_compile REINHARD FILMIC UNCHARTED
			
			#include "UnityCG.cginc"

			struct appdata
			{
				half4 vertex : POSITION;
				half2 uv : TEXCOORD0;
			};

			struct v2f
			{
				half2 uv : TEXCOORD0;
				half4 vertex : SV_POSITION;
			};

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
				o.uv = v.uv;
				return o;
			}
			
			uniform sampler2D _MainTex;

			uniform half Exposure;
			uniform half Gamma;

#if REINHARD
			inline half3 simpleReinhardToneMapping(half3 color)
			{
				half gammaReciprocal = 1.0 / Gamma;
				color *= Exposure / (1.0 + color / Exposure);
				color = pow(color, half3(gammaReciprocal, gammaReciprocal, gammaReciprocal));
				return color;
			}
#endif

#if FILMIC
			inline half3 filmicToneMapping(half3 color)
			{
				color = max(half3(0.0, 0.0, 0.0), color - half3(0.004, 0.004, 0.004));
				color = (color * (6.2 * color + 0.5)) / (color * (6.2 * color + 1.7) + 0.06);
				return color;
			}
#endif

#if UNCHARTED
			inline half3 Uncharted2ToneMapping(half3 color)
			{
				half A = 0.15;
				half B = 0.50;
				half C = 0.10;
				half D = 0.20;
				half E = 0.02;
				half F = 0.30;
				half W = 11.2;
				half exposure = Exposure;
				half gammaReciprocal = 1.0 / Gamma;
				color *= exposure;
				color = ((color * (A * color + C * B) + D * E) / (color * (A * color + B) + D * F)) - E / F;
				half white = ((W * (A * W + C * B) + D * E) / (W * (A * W + B) + D * F)) - E / F;
				color /= white;
				color = pow(color, half3(gammaReciprocal, gammaReciprocal, gammaReciprocal));
				return color;
			}
#endif

			half4 frag (v2f i) : SV_Target
			{
				half3 texColor = tex2D(_MainTex, i.uv).rgb;
				half3 toneMappedColor = half3(0.0, 0.0, 0.0);

#if REINHARD
				toneMappedColor = simpleReinhardToneMapping(texColor);
#endif

#if FILMIC
				toneMappedColor = filmicToneMapping(texColor);
#endif

#if UNCHARTED
				toneMappedColor = Uncharted2ToneMapping(texColor);
#endif

				return half4(toneMappedColor, 1.0);
			}

			ENDCG
		}
	}
}