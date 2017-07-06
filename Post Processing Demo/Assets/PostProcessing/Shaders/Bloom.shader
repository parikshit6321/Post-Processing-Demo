Shader "Hidden/Bloom"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
	}

	CGINCLUDE

	#include "UnityCG.cginc"

	uniform sampler2D	_MainTex;
	uniform half4		_MainTex_TexelSize;

	uniform sampler2D	BlurredTexture4;
	uniform sampler2D	BlurredTexture8;
	uniform sampler2D	BlurredTexture16;

	uniform half		Threshold;

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
	};

	v2f vert(appdata v)
	{
		v2f o;
		o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
		
		o.uv = v.uv;
		
		return o;
	}

	v2f_blur vert_horizontal_blur(appdata v)
	{
		half unitX = _MainTex_TexelSize.x;

		v2f_blur o;

		o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
		
		o.uv = v.uv;

		o.offset1 = half2(o.uv.x - unitX, o.uv.y);
		o.offset2 = half2(o.uv.x, o.uv.y);
		o.offset3 = half2(o.uv.x + unitX, o.uv.y);
		
		return o;
	}

	v2f_blur vert_vertical_blur(appdata v)
	{
		half unitY = _MainTex_TexelSize.y;

		v2f_blur o;

		o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
		
		o.uv = v.uv;

		o.offset1 = half2(o.uv.x, o.uv.y - unitY);
		o.offset2 = half2(o.uv.x, o.uv.y);
		o.offset3 = half2(o.uv.x, o.uv.y + unitY);

		return o;
	}

	half4 frag_bright(v2f i) : SV_Target
	{
		half4 col = tex2D(_MainTex, i.uv);
		half average = (col.r + col.g + col.b) * 0.33;
		half4 final = lerp(half4(0.0, 0.0, 0.0, 1.0), col, saturate(average - Threshold));
		return final;
	}

	half4 frag_blur(v2f_blur i) : SV_TARGET
	{
		half4 col;
		
		col = tex2D(_MainTex, i.offset1);
		col += tex2D(_MainTex, i.offset2);
		col += tex2D(_MainTex, i.offset3);

		col *= 0.33;

		return col;
	}

	half4 frag_blend_high(v2f i) : SV_TARGET
	{
		half4 col = tex2D(_MainTex, i.uv);
		half4 blurred4 = tex2D(BlurredTexture4, i.uv);
		half4 blurred8 = tex2D(BlurredTexture8, i.uv);
		half4 blurred16 = tex2D(BlurredTexture16, i.uv);
		return half4(col.rgb + blurred4.rgb + blurred8.rgb + blurred16.rgb, col.a);
	}

	half4 frag_blend_medium(v2f i) : SV_TARGET
	{
		half4 col = tex2D(_MainTex, i.uv);
		half4 blurred4 = tex2D(BlurredTexture4, i.uv);
		half4 blurred8 = tex2D(BlurredTexture8, i.uv);
		return half4(col.rgb + blurred4.rgb + blurred8.rgb, col.a);
	}

	half4 frag_blend_low(v2f i) : SV_TARGET
	{
		half4 col = tex2D(_MainTex, i.uv);
		half4 blurred4 = tex2D(BlurredTexture4, i.uv);
		return half4(col.rgb + blurred4.rgb, col.a);
	}

	ENDCG

	SubShader
	{
		// No culling or depth
		Cull Off ZWrite Off ZTest Always

		// 0 : Bright Pass
		Pass
		{
			CGPROGRAM
			
			#pragma fragmentoption ARB_precision_hint_fastest
			#pragma vertex vert
			#pragma fragment frag_bright
			#pragma target 3.0
			
			ENDCG
		}

		// 1 : Horizontal Blur Pass
		Pass
		{
			CGPROGRAM

			#pragma fragmentoption ARB_precision_hint_fastest
			#pragma vertex vert_horizontal_blur
			#pragma fragment frag_blur
			#pragma target 3.0

			ENDCG
		}

		// 2 : Vertical Blur Pass
		Pass
		{
			CGPROGRAM

			#pragma fragmentoption ARB_precision_hint_fastest
			#pragma vertex vert_vertical_blur
			#pragma fragment frag_blur
			#pragma target 3.0

			ENDCG
		}

		// 3 : Blend Pass - High Quality
		Pass
		{
			CGPROGRAM

			#pragma fragmentoption ARB_precision_hint_fastest
			#pragma vertex vert
			#pragma fragment frag_blend_high
			#pragma target 3.0

			ENDCG
		}

		// 4 : Blend Pass - Medium Quality
		Pass
		{
			CGPROGRAM

			#pragma fragmentoption ARB_precision_hint_fastest
			#pragma vertex vert
			#pragma fragment frag_blend_medium
			#pragma target 3.0

			ENDCG
		}

		// 5 : Blend Pass - Low Quality
		Pass
		{
			CGPROGRAM

			#pragma fragmentoption ARB_precision_hint_fastest
			#pragma vertex vert
			#pragma fragment frag_blend_low
			#pragma target 3.0

			ENDCG
		}
	}
}