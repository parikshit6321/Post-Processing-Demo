Shader "Hidden/SpriteBasedBokehDOF"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
	}

	CGINCLUDE

	#include "UnityCG.cginc"

	uniform sampler2D	_MainTex;
	uniform sampler2D	_CameraDepthTexture;
	uniform sampler2D	_Sprite;
	uniform sampler2D	_Blurred;
	
	uniform float4		_MainTex_TexelSize;

	uniform float		_BokehRadius;
	uniform float		_BokehIntensity;
	uniform float		_LuminanceThreshold;
	uniform float		_BokehThreshold;
	uniform float		_FocusDistance;

	struct appdata
	{
		float4 vertex : POSITION;
		float2 uv : TEXCOORD0;
	};

	struct v2f
	{
		float2 uv : TEXCOORD0;
		float4 vertex : SV_POSITION;
	};

	v2f vert(appdata v)
	{
		v2f o;
		o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
		o.uv = v.uv;
		return o;
	}

	half4 frag_blur(v2f input) : SV_Target
	{
		half4 finalColor = float4(0.0, 0.0, 0.0, 1.0);
		
		half numberOfSamples = 0.0;

		half i, j;

		float depth = LinearEyeDepth(tex2D(_CameraDepthTexture, input.uv));
		half blurriness = 0.0;

#if defined(LOW_BOKEH)
		
		if (depth > _FocusDistance)
			blurriness = 1.0;

		for (i = -3.0; i < 4.0; i += 1.0)
		{
			for (j = -3.0; j < 4.0; j += 1.0)
			{
				half2 mask_coords;
				mask_coords.x = 48.0 - (((i + 3.0) * 8.0) / 48.0);
				mask_coords.y = 48.0 - (((j + 3.0) * 8.0) / 48.0);
				half mask = tex2D(_Sprite, mask_coords);

				if (mask > 0.1)
				{
					half2 offset = half2(i * _MainTex_TexelSize.x * _BokehRadius * blurriness, j * _MainTex_TexelSize.y * _BokehRadius * blurriness);
					half4 extractedColor = tex2D(_MainTex, input.uv + offset);

					half luminance = ((0.2126 * extractedColor.r) + (0.7152 * extractedColor.g) + (0.0722 * extractedColor.b));

					if (luminance > _LuminanceThreshold && blurriness > _BokehThreshold)
						extractedColor *= _BokehIntensity;

					finalColor += extractedColor;

					numberOfSamples += 1.0;
				}
			}
		}

#endif

#if defined(MEDIUM_BOKEH)

		float xMinusf = depth - _FocusDistance;
		float xMinusfSquared = xMinusf * xMinusf;

		blurriness = xMinusfSquared / (1.0 + xMinusfSquared);

		for (i = -6.0; i < 7.0; i += 1.0)
		{
			for (j = -6.0; j < 7.0; j += 1.0)
			{
				half2 mask_coords;
				mask_coords.x = 48.0 - (((i + 6.0) * 4.0) / 48.0);
				mask_coords.y = 48.0 - (((j + 6.0) * 4.0) / 48.0);
				half mask = tex2D(_Sprite, mask_coords);

				if (mask > 0.1)
				{
					half2 offset = half2(i * _MainTex_TexelSize.x * _BokehRadius * blurriness, j * _MainTex_TexelSize.y * _BokehRadius * blurriness);
					half4 extractedColor = tex2D(_MainTex, input.uv + offset);

					half luminance = ((0.2126 * extractedColor.r) + (0.7152 * extractedColor.g) + (0.0722 * extractedColor.b));

					if (luminance > _LuminanceThreshold && blurriness > _BokehThreshold)
						extractedColor *= _BokehIntensity;

					finalColor += extractedColor;

					numberOfSamples += 1.0;
				}
			}
		}

#endif

#if defined(HIGH_BOKEH)

		float xMinusf = depth - _FocusDistance;
		float xMinusfSquared = xMinusf * xMinusf;
		
		blurriness = xMinusfSquared / (1.0 + xMinusfSquared);

		for (i = -12.0; i < 13.0; i += 1.0)
		{
			for (j = -12.0; j < 13.0; j += 1.0)
			{
				half2 mask_coords;
				mask_coords.x = 48.0 - (((i + 12.0) * 2.0) / 48.0);
				mask_coords.y = 48.0 - (((j + 12.0) * 2.0) / 48.0);
				half mask = tex2D(_Sprite, mask_coords);

				if (mask > 0.1)
				{
					half2 offset = half2(i * _MainTex_TexelSize.x * _BokehRadius * blurriness, j * _MainTex_TexelSize.y * _BokehRadius * blurriness);
					half4 extractedColor = tex2D(_MainTex, input.uv + offset);

					half luminance = ((0.2126 * extractedColor.r) + (0.7152 * extractedColor.g) + (0.0722 * extractedColor.b));

					if (luminance > _LuminanceThreshold && blurriness > _BokehThreshold)
						extractedColor *= _BokehIntensity;

					finalColor += extractedColor;

					numberOfSamples += 1.0;
				}
			}
		}

#endif

#if defined(ULTRA_HIGH_BOKEH)

		float xMinusf = depth - _FocusDistance;
		float xMinusfSquared = xMinusf * xMinusf;

		blurriness = xMinusfSquared / (1.0 + xMinusfSquared);

		for (i = -24.0; i < 25.0; i += 1.0)
		{
			for (j = -24.0; j < 25.0; j += 1.0)
			{
				half2 mask_coords;
				mask_coords.x = 48.0 - ((i + 24.0) / 48.0);
				mask_coords.y = 48.0 - ((j + 24.0) / 48.0);
				float mask = tex2D(_Sprite, mask_coords);

				if (mask > 0.1)
				{
					half2 offset = half2(i * _MainTex_TexelSize.x * _BokehRadius * blurriness, j * _MainTex_TexelSize.y * _BokehRadius * blurriness);
					half4 extractedColor = tex2D(_MainTex, input.uv + offset);
					
					half luminance = ((0.2126 * extractedColor.r) + (0.7152 * extractedColor.g) + (0.0722 * extractedColor.b));
					
					if (luminance > _LuminanceThreshold && blurriness > _BokehThreshold)
						extractedColor *= _BokehIntensity;

					finalColor += extractedColor;

					numberOfSamples += 1.0;
				}
			}
		}

#endif

		finalColor /= numberOfSamples;

		finalColor.a = blurriness;

		return finalColor;
	}

	half4 frag_blend(v2f input) : SV_Target
	{
		half4 textureColor = tex2D(_MainTex, input.uv);
		half4 blurredColor = tex2D(_Blurred, input.uv);

		half lerpFactor = blurredColor.a;

		half4 finalColor = half4(lerp(textureColor.xyz, blurredColor.xyz, lerpFactor), textureColor.a);

		return finalColor;
	}

	ENDCG

	SubShader
	{
		// No culling or depth
		Cull Off ZWrite Off ZTest Always

		// 0 : Sprite based Blur Pass
		Pass
		{
			CGPROGRAM
			
			#pragma multi_compile LOW_BOKEH MEDIUM_BOKEH HIGH_BOKEH ULTRA_HIGH_BOKEH
			#pragma fragmentoption ARB_precision_hint_fastest
			#pragma vertex vert
			#pragma fragment frag_blur
			#pragma target 3.0
			
			ENDCG
		}

		// 1 : Blending Pass
		Pass
		{
			CGPROGRAM

			#pragma fragmentoption ARB_precision_hint_fastest
			#pragma vertex vert
			#pragma fragment frag_blend
			#pragma target 3.0

			ENDCG
		}
	}
}