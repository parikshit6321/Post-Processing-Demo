Shader "Hidden/BokehDOF"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
	}

	CGINCLUDE

	#include "UnityCG.cginc"

	uniform sampler2D	_MainTex;
	uniform half4		_MainTex_TexelSize;

	uniform sampler2D	_CameraDepthTexture;
	uniform sampler2D	BlurredTex;

	uniform float		DepthNearCutOff;
	uniform float		DepthFarCutOff;
	uniform half		BlurStep;
	uniform float		DepthThreshold;

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

	struct v2f_blur
	{
		float2 uv : TEXCOORD0;
		float4 vertex : SV_POSITION;
		half2 offset1 : TEXCOORD1;
		half2 offset2 : TEXCOORD2;
		half2 offset3 : TEXCOORD3;
		half2 offset4 : TEXCOORD4;
		half2 offset5 : TEXCOORD5;
	};

	// Simple vertex shader
	v2f vert(appdata v)
	{
		v2f o;
		o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
		o.uv = v.uv;
		return o;
	}

	// Primary Diagonal Blur vertex shader
	v2f_blur vert_primary_diagonol_blur(appdata v)
	{
		half unitX = _MainTex_TexelSize.x * BlurStep;
		half unitY = _MainTex_TexelSize.y * BlurStep;

		v2f_blur o;

		o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);

		o.uv = v.uv;

		o.offset1 = half2(o.uv.x - (2.0 * unitX), o.uv.y - (2.0 * unitY));
		o.offset2 = half2(o.uv.x - (unitX), o.uv.y - (unitY));
		o.offset3 = half2(o.uv.x, o.uv.y);
		o.offset4 = half2(o.uv.x + (unitX), o.uv.y + (unitY));
		o.offset5 = half2(o.uv.x + (2.0 * unitX), o.uv.y + (2.0 * unitY));

		return o;
	}

	// Secondary diagonal blur vertex shader
	v2f_blur vert_secondary_diagonol_blur(appdata v)
	{
		half unitX = _MainTex_TexelSize.x * BlurStep;
		half unitY = _MainTex_TexelSize.y * BlurStep;

		v2f_blur o;

		o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);

		o.uv = v.uv;

		o.offset1 = half2(o.uv.x - (2.0 * unitX), o.uv.y + (2.0 * unitY));
		o.offset2 = half2(o.uv.x - (unitX), o.uv.y + (unitY));
		o.offset3 = half2(o.uv.x, o.uv.y);
		o.offset4 = half2(o.uv.x + (unitX), o.uv.y - (unitY));
		o.offset5 = half2(o.uv.x + (2.0 * unitX), o.uv.y - (2.0 * unitY));

		return o;
	}

	// Vertical blur vertex shader
	v2f_blur vert_vertical_blur(appdata v)
	{
		half unitY = _MainTex_TexelSize.y * BlurStep;

		v2f_blur o;

		o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);

		o.uv = v.uv;

		o.offset1 = half2(o.uv.x, o.uv.y - (2.0 * unitY));
		o.offset2 = half2(o.uv.x, o.uv.y - (unitY));
		o.offset3 = half2(o.uv.x, o.uv.y);
		o.offset4 = half2(o.uv.x, o.uv.y + (unitY));
		o.offset5 = half2(o.uv.x, o.uv.y + (2.0 * unitY));

		return o;
	}

	// Common blurring fragment shader for hexagonal bokeh
	half4 frag_blur(v2f_blur i) : SV_TARGET
	{
		half4 baseCol = tex2D(_MainTex, i.offset3);
		half4 col = baseCol;

#if defined(COLOR_BLEEDING_FIX_ON)

		float depth3 = LinearEyeDepth(tex2D(_CameraDepthTexture, i.offset3));
		
		float depth13 = abs(LinearEyeDepth(tex2D(_CameraDepthTexture, i.offset1)) - depth3);
		float depth23 = abs(LinearEyeDepth(tex2D(_CameraDepthTexture, i.offset2)) - depth3);
		float depth43 = abs(LinearEyeDepth(tex2D(_CameraDepthTexture, i.offset4)) - depth3);
		float depth53 = abs(LinearEyeDepth(tex2D(_CameraDepthTexture, i.offset5)) - depth3);

		col += lerp(tex2D(_MainTex, i.offset1), baseCol, saturate(depth13 - DepthThreshold));
		col += lerp(tex2D(_MainTex, i.offset2), baseCol, saturate(depth23 - DepthThreshold));
		col += lerp(tex2D(_MainTex, i.offset4), baseCol, saturate(depth43 - DepthThreshold));
		col += lerp(tex2D(_MainTex, i.offset5), baseCol, saturate(depth53 - DepthThreshold));

#endif

#if defined(COLOR_BLEEDING_FIX_OFF)

		col += tex2D(_MainTex, i.offset1);
		col += tex2D(_MainTex, i.offset2);
		col += tex2D(_MainTex, i.offset4);
		col += tex2D(_MainTex, i.offset5);

#endif

		col *= 0.2;

		return col;
	}

	// Disc blur fragment shader
	half4 frag_disc_blur(v2f i) : SV_TARGET
	{
		half4 baseCol = tex2D(_MainTex, i.uv);
		half4 col = baseCol;

		half X = _MainTex_TexelSize.x * BlurStep;
		half Y = _MainTex_TexelSize.y * BlurStep;

#if defined(COLOR_BLEEDING_FIX_ON)
		
		float depth = LinearEyeDepth(tex2D(_CameraDepthTexture, i.uv));

		col += lerp(tex2D(_MainTex, i.uv + half2(-X, 3.0 * Y)), baseCol, saturate(abs(LinearEyeDepth(tex2D(_CameraDepthTexture, i.uv + half2(-X, 3.0 * Y))) - depth) - DepthThreshold));
		col += lerp(tex2D(_MainTex, i.uv + half2(0.0, 3.0 * Y)), baseCol, saturate(abs(LinearEyeDepth(tex2D(_CameraDepthTexture, i.uv + half2(0.0, 3.0 * Y))) - depth) - DepthThreshold));
		col += lerp(tex2D(_MainTex, i.uv + half2(X, 3.0 * Y)), baseCol, saturate(abs(LinearEyeDepth(tex2D(_CameraDepthTexture, i.uv + half2(X, 3.0 * Y))) - depth) - DepthThreshold));
		
		col += lerp(tex2D(_MainTex, i.uv + half2(-2.0 * X, 2.0 * Y)), baseCol, saturate(abs(LinearEyeDepth(tex2D(_CameraDepthTexture, i.uv + half2(-2.0 * X, 2.0 * Y))) - depth) - DepthThreshold));
		col += lerp(tex2D(_MainTex, i.uv + half2(-X, 2.0 * Y)), baseCol, saturate(abs(LinearEyeDepth(tex2D(_CameraDepthTexture, i.uv + half2(-X, 2.0 * Y))) - depth) - DepthThreshold));
		col += lerp(tex2D(_MainTex, i.uv + half2(0.0, 2.0 * Y)), baseCol, saturate(abs(LinearEyeDepth(tex2D(_CameraDepthTexture, i.uv + half2(0.0, 2.0 * Y))) - depth) - DepthThreshold));
		col += lerp(tex2D(_MainTex, i.uv + half2(X, 2.0 * Y)), baseCol, saturate(abs(LinearEyeDepth(tex2D(_CameraDepthTexture, i.uv + half2(X, 2.0 * Y))) - depth) - DepthThreshold));
		col += lerp(tex2D(_MainTex, i.uv + half2(2.0 * X, 2.0 * Y)), baseCol, saturate(abs(LinearEyeDepth(tex2D(_CameraDepthTexture, i.uv + half2(2.0 * X, 2.0 * Y))) - depth) - DepthThreshold));

		col += lerp(tex2D(_MainTex, i.uv + half2(-3.0 * X, Y)), baseCol, saturate(abs(LinearEyeDepth(tex2D(_CameraDepthTexture, i.uv + half2(-3.0 * X, Y))) - depth) - DepthThreshold));
		col += lerp(tex2D(_MainTex, i.uv + half2(-2.0 * X, Y)), baseCol, saturate(abs(LinearEyeDepth(tex2D(_CameraDepthTexture, i.uv + half2(-2.0 * X, Y))) - depth) - DepthThreshold));
		col += lerp(tex2D(_MainTex, i.uv + half2(-X, Y)), baseCol, saturate(abs(LinearEyeDepth(tex2D(_CameraDepthTexture, i.uv + half2(-X, Y))) - depth) - DepthThreshold));
		col += lerp(tex2D(_MainTex, i.uv + half2(0.0, Y)), baseCol, saturate(abs(LinearEyeDepth(tex2D(_CameraDepthTexture, i.uv + half2(0.0, Y))) - depth) - DepthThreshold));
		col += lerp(tex2D(_MainTex, i.uv + half2(X, Y)), baseCol, saturate(abs(LinearEyeDepth(tex2D(_CameraDepthTexture, i.uv + half2(X, Y))) - depth) - DepthThreshold));
		col += lerp(tex2D(_MainTex, i.uv + half2(2.0 * X, Y)), baseCol, saturate(abs(LinearEyeDepth(tex2D(_CameraDepthTexture, i.uv + half2(2.0 * X, Y))) - depth) - DepthThreshold));
		col += lerp(tex2D(_MainTex, i.uv + half2(3.0 * X, Y)), baseCol, saturate(abs(LinearEyeDepth(tex2D(_CameraDepthTexture, i.uv + half2(3.0 * X, Y))) - depth) - DepthThreshold));

		col += lerp(tex2D(_MainTex, i.uv + half2(-3.0 * X, 0.0)), baseCol, saturate(abs(LinearEyeDepth(tex2D(_CameraDepthTexture, i.uv + half2(-3.0 * X, 0.0))) - depth) - DepthThreshold));
		col += lerp(tex2D(_MainTex, i.uv + half2(-2.0 * X, 0.0)), baseCol, saturate(abs(LinearEyeDepth(tex2D(_CameraDepthTexture, i.uv + half2(-2.0 * X, 0.0))) - depth) - DepthThreshold));
		col += lerp(tex2D(_MainTex, i.uv + half2(-X, 0.0)), baseCol, saturate(abs(LinearEyeDepth(tex2D(_CameraDepthTexture, i.uv + half2(-X, 0.0))) - depth) - DepthThreshold));
		col += lerp(tex2D(_MainTex, i.uv + half2(X, 0.0)), baseCol, saturate(abs(LinearEyeDepth(tex2D(_CameraDepthTexture, i.uv + half2(X, 0.0))) - depth) - DepthThreshold));
		col += lerp(tex2D(_MainTex, i.uv + half2(2.0 * X, 0.0)), baseCol, saturate(abs(LinearEyeDepth(tex2D(_CameraDepthTexture, i.uv + half2(2.0 * X, 0.0))) - depth) - DepthThreshold));
		col += lerp(tex2D(_MainTex, i.uv + half2(3.0 * X, 0.0)), baseCol, saturate(abs(LinearEyeDepth(tex2D(_CameraDepthTexture, i.uv + half2(3.0 * X, 0.0))) - depth) - DepthThreshold));

		col += lerp(tex2D(_MainTex, i.uv + half2(-3.0 * X, -Y)), baseCol, saturate(abs(LinearEyeDepth(tex2D(_CameraDepthTexture, i.uv + half2(-3.0 * X, -Y))) - depth) - DepthThreshold));
		col += lerp(tex2D(_MainTex, i.uv + half2(-2.0 * X, -Y)), baseCol, saturate(abs(LinearEyeDepth(tex2D(_CameraDepthTexture, i.uv + half2(-2.0 * X, -Y))) - depth) - DepthThreshold));
		col += lerp(tex2D(_MainTex, i.uv + half2(-X, -Y)), baseCol, saturate(abs(LinearEyeDepth(tex2D(_CameraDepthTexture, i.uv + half2(-X, -Y))) - depth) - DepthThreshold));
		col += lerp(tex2D(_MainTex, i.uv + half2(0.0, -Y)), baseCol, saturate(abs(LinearEyeDepth(tex2D(_CameraDepthTexture, i.uv + half2(0.0, -Y))) - depth) - DepthThreshold));
		col += lerp(tex2D(_MainTex, i.uv + half2(X, -Y)), baseCol, saturate(abs(LinearEyeDepth(tex2D(_CameraDepthTexture, i.uv + half2(X, -Y))) - depth) - DepthThreshold));
		col += lerp(tex2D(_MainTex, i.uv + half2(2.0 * X, -Y)), baseCol, saturate(abs(LinearEyeDepth(tex2D(_CameraDepthTexture, i.uv + half2(2.0 * X, -Y))) - depth) - DepthThreshold));
		col += lerp(tex2D(_MainTex, i.uv + half2(3.0 * X, -Y)), baseCol, saturate(abs(LinearEyeDepth(tex2D(_CameraDepthTexture, i.uv + half2(3.0 * X, -Y))) - depth) - DepthThreshold));

		col += lerp(tex2D(_MainTex, i.uv + half2(-2.0 * X, -2.0 * Y)), baseCol, saturate(abs(LinearEyeDepth(tex2D(_CameraDepthTexture, i.uv + half2(-2.0 * X, -2.0 * Y))) - depth) - DepthThreshold));
		col += lerp(tex2D(_MainTex, i.uv + half2(-X, -2.0 * Y)), baseCol, saturate(abs(LinearEyeDepth(tex2D(_CameraDepthTexture, i.uv + half2(-X, -2.0 * Y))) - depth) - DepthThreshold));
		col += lerp(tex2D(_MainTex, i.uv + half2(0.0, -2.0 * Y)), baseCol, saturate(abs(LinearEyeDepth(tex2D(_CameraDepthTexture, i.uv + half2(0.0, -2.0 * Y))) - depth) - DepthThreshold));
		col += lerp(tex2D(_MainTex, i.uv + half2(X, -2.0 * Y)), baseCol, saturate(abs(LinearEyeDepth(tex2D(_CameraDepthTexture, i.uv + half2(X, -2.0 * Y))) - depth) - DepthThreshold));
		col += lerp(tex2D(_MainTex, i.uv + half2(2.0 * X, -2.0 * Y)), baseCol, saturate(abs(LinearEyeDepth(tex2D(_CameraDepthTexture, i.uv + half2(2.0 * X, -2.0 * Y))) - depth) - DepthThreshold));

		col += lerp(tex2D(_MainTex, i.uv + half2(-X, -3.0 * Y)), baseCol, saturate(abs(LinearEyeDepth(tex2D(_CameraDepthTexture, i.uv + half2(-X, -3.0 * Y))) - depth) - DepthThreshold));
		col += lerp(tex2D(_MainTex, i.uv + half2(0.0, -3.0 * Y)), baseCol, saturate(abs(LinearEyeDepth(tex2D(_CameraDepthTexture, i.uv + half2(0.0, -3.0 * Y))) - depth) - DepthThreshold));
		col += lerp(tex2D(_MainTex, i.uv + half2(X, -3.0 * Y)), baseCol, saturate(abs(LinearEyeDepth(tex2D(_CameraDepthTexture, i.uv + half2(X, -3.0 * Y))) - depth) - DepthThreshold));

#endif

#if defined(COLOR_BLEEDING_FIX_OFF)

		col += tex2D(_MainTex, i.uv + half2(-X, 3.0 * Y));
		col += tex2D(_MainTex, i.uv + half2(0.0, 3.0 * Y));
		col += tex2D(_MainTex, i.uv + half2(X, 3.0 * Y));

		col += tex2D(_MainTex, i.uv + half2(-2.0 * X, 2.0 * Y));
		col += tex2D(_MainTex, i.uv + half2(-X, 2.0 * Y));
		col += tex2D(_MainTex, i.uv + half2(0.0, 2.0 * Y));
		col += tex2D(_MainTex, i.uv + half2(X, 2.0 * Y));
		col += tex2D(_MainTex, i.uv + half2(2.0 * X, 2.0 * Y));

		col += tex2D(_MainTex, i.uv + half2(-3.0 * X, Y));
		col += tex2D(_MainTex, i.uv + half2(-2.0 * X, Y));
		col += tex2D(_MainTex, i.uv + half2(-X, Y));
		col += tex2D(_MainTex, i.uv + half2(0.0, Y));
		col += tex2D(_MainTex, i.uv + half2(X, Y));
		col += tex2D(_MainTex, i.uv + half2(2.0 * X, Y));
		col += tex2D(_MainTex, i.uv + half2(3.0 * X, Y));

		col += tex2D(_MainTex, i.uv + half2(-3.0 * X, 0.0));
		col += tex2D(_MainTex, i.uv + half2(-2.0 * X, 0.0));
		col += tex2D(_MainTex, i.uv + half2(-X, 0.0));
		col += tex2D(_MainTex, i.uv + half2(X, 0.0));
		col += tex2D(_MainTex, i.uv + half2(2.0 * X, 0.0));
		col += tex2D(_MainTex, i.uv + half2(3.0 * X, 0.0));

		col += tex2D(_MainTex, i.uv + half2(-3.0 * X, -Y));
		col += tex2D(_MainTex, i.uv + half2(-2.0 * X, -Y));
		col += tex2D(_MainTex, i.uv + half2(-X, -Y));
		col += tex2D(_MainTex, i.uv + half2(0.0, -Y));
		col += tex2D(_MainTex, i.uv + half2(X, -Y));
		col += tex2D(_MainTex, i.uv + half2(2.0 * X, -Y));
		col += tex2D(_MainTex, i.uv + half2(3.0 * X, -Y));

		col += tex2D(_MainTex, i.uv + half2(-2.0 * X, -2.0 * Y));
		col += tex2D(_MainTex, i.uv + half2(-X, -2.0 * Y));
		col += tex2D(_MainTex, i.uv + half2(0.0, -2.0 * Y));
		col += tex2D(_MainTex, i.uv + half2(X, -2.0 * Y));
		col += tex2D(_MainTex, i.uv + half2(2.0 * X, -2.0 * Y));

		col += tex2D(_MainTex, i.uv + half2(-X, -3.0 * Y));
		col += tex2D(_MainTex, i.uv + half2(0.0, -3.0 * Y));
		col += tex2D(_MainTex, i.uv + half2(X, -3.0 * Y));

#endif
		
		col /= 37;

		return col;
	}

	// Final blending fragment shader
	half4 frag_blend(v2f i) : SV_Target
	{
		half4 texColor = tex2D(_MainTex, i.uv);
		half4 blurColor = tex2D(BlurredTex, i.uv);
		
		float depth = LinearEyeDepth(tex2D(_CameraDepthTexture, i.uv));
		
		half4 finalColor = lerp(texColor, blurColor, saturate(depth - DepthFarCutOff));
		finalColor = lerp(finalColor, blurColor, saturate(DepthNearCutOff - depth));

		return finalColor;
	}

	ENDCG

	SubShader
	{
		// No culling or depth
		Cull Off ZWrite Off ZTest Always

		// 0 : Blending Pass
		Pass
		{
			CGPROGRAM

			#pragma fragmentoption ARB_precision_hint_fastest
			#pragma vertex vert
			#pragma fragment frag_blend
			#pragma target 3.0

			ENDCG
		}
		// 1 : Vertical Blur Pass
		Pass
		{
			CGPROGRAM
			
			#pragma multi_compile COLOR_BLEEDING_FIX_ON COLOR_BLEEDING_FIX_OFF
			#pragma fragmentoption ARB_precision_hint_fastest
			#pragma vertex vert_vertical_blur
			#pragma fragment frag_blur
			#pragma target 3.0

			ENDCG
		}
		// 2 : Primary Diagonal Blur Pass
		Pass
		{
			CGPROGRAM

			#pragma multi_compile COLOR_BLEEDING_FIX_ON COLOR_BLEEDING_FIX_OFF
			#pragma fragmentoption ARB_precision_hint_fastest
			#pragma vertex vert_primary_diagonol_blur
			#pragma fragment frag_blur
			#pragma target 3.0

			ENDCG
		}
		// 3 : Secondary Diagonal Blur Pass
		Pass
		{
			CGPROGRAM

			#pragma multi_compile COLOR_BLEEDING_FIX_ON COLOR_BLEEDING_FIX_OFF
			#pragma fragmentoption ARB_precision_hint_fastest
			#pragma vertex vert_secondary_diagonol_blur 
			#pragma fragment frag_blur
			#pragma target 3.0

			ENDCG
		}
		// 4 : Disc Blur Pass
		Pass
		{
			CGPROGRAM

			#pragma multi_compile COLOR_BLEEDING_FIX_ON COLOR_BLEEDING_FIX_OFF
			#pragma fragmentoption ARB_precision_hint_fastest
			#pragma vertex vert 
			#pragma fragment frag_disc_blur
			#pragma target 3.0

			ENDCG
		}
	}
}