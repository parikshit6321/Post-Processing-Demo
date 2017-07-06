Shader "Hidden/GodRays"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
	}

	CGINCLUDE

#include "UnityCG.cginc"

	uniform sampler2D	_MainTex;
	uniform half4		_MainTex_TexelSize;

	uniform sampler2D	_CameraGBufferTexture0;	// Diffuse color (RGB), occlusion (A)
	
	uniform sampler2D	GodTexture;

	// God rays parameters
	uniform half		Weight;
	uniform half		Decay;
	uniform half		Exposure;
	uniform half		NumOfSamples;
	uniform half2		SunScreenPos;

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

	fixed4 frag_god_rays(v2f i) : SV_Target
	{
		half2 texCoord = i.uv;

		// Calculate vector from pixel to light source in screen space.  
		half2 deltaTexCoord = (texCoord - SunScreenPos.xy);

		// Divide by number of samples and scale by control factor.  
		deltaTexCoord *= 1.0f / NumOfSamples;

		// Store initial sample.  
		half3 color = tex2D(_MainTex, texCoord);

		half3 sample;
		half step;
		half IlluminationDecay = 1.0;

		// Evaluate summation from Equation 3 NUM_SAMPLES iterations.  
		for (step = 0; step < NumOfSamples; step += 1.0)
		{
			// Step sample location along ray.  
			texCoord -= deltaTexCoord;

			// Retrieve sample at new location.  
			sample = tex2D(_MainTex, texCoord);

			// Apply sample attenuation scale/decay factors.  
			sample *= IlluminationDecay * Weight;

			// Accumulate combined color.  
			color += sample;

			// Update exponential decay factor.  
			IlluminationDecay *= Decay;
		}

		return float4(color, 1);
	}

	half4 frag_horizontal_blur(v2f_blur i) : SV_TARGET
	{
		half4 col;

		col = tex2D(_MainTex, i.offset1);
		col += tex2D(_MainTex, i.offset2);
		col += tex2D(_MainTex, i.offset3);

		col *= 0.33;

		return col;
	}

	half4 frag_vertical_blur(v2f_blur i) : SV_TARGET
	{
		half4 col;

		col = tex2D(_MainTex, i.offset1);
		col += tex2D(_MainTex, i.offset2);
		col += tex2D(_MainTex, i.offset3);

		col *= 0.33;

		return col;
	}

	half4 frag_blend(v2f i) : SV_TARGET
	{
		half4 col = tex2D(_MainTex, i.uv);
		half4 godCol = tex2D(GodTexture, i.uv);

		half4 final = lerp(col, godCol, Exposure);

		return final;
	}

	half4 frag_mask(v2f i) : SV_TARGET
	{
		half4 finalColor = tex2D(_MainTex, i.uv);
		half occlusion = tex2D(_CameraGBufferTexture0, i.uv).a;
		finalColor = finalColor * (1.0 - occlusion) + half4(0.0, 0.0, 0.0, 1.0) * occlusion;
		return finalColor;
	}

	ENDCG

	SubShader
	{
		// No culling or depth
		Cull Off ZWrite Off ZTest Always

		// 0 : Mask Pass
		Pass
		{
			CGPROGRAM

			#pragma fragmentoption ARB_precision_hint_fastest
			#pragma vertex vert
			#pragma fragment frag_mask
			#pragma target 3.0

			ENDCG
		}

		// 1 : God Rays Pass
		Pass
		{
			CGPROGRAM
			
			#pragma fragmentoption ARB_precision_hint_fastest
			#pragma vertex vert
			#pragma fragment frag_god_rays
			#pragma target 3.0
			
			ENDCG
		}

		// 2 : Horizontal Blur Pass
		Pass
		{
			CGPROGRAM
			
			#pragma fragmentoption ARB_precision_hint_fastest
			#pragma vertex vert_horizontal_blur
			#pragma fragment frag_horizontal_blur
			#pragma target 3.0

			ENDCG
		}

		// 3 : Vertical Blur Pass
		Pass
		{
			CGPROGRAM

			#pragma fragmentoption ARB_precision_hint_fastest
			#pragma vertex vert_vertical_blur
			#pragma fragment frag_vertical_blur
			#pragma target 3.0

			ENDCG
		}

		// 4 : Blending Pass
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