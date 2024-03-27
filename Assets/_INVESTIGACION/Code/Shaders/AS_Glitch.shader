// Made with Amplify Shader Editor v1.9.1.2
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "AS_Glitch"
{
	Properties
	{
		[HideInInspector] _EmissionColor("Emission Color", Color) = (1,1,1,1)
		[HideInInspector] _AlphaCutoff("Alpha Cutoff ", Range(0, 1)) = 0.5
		[HideInInspector][NoScaleOffset]_MaskMap("MaskMap", 2D) = "white" {}
		[ASEBegin]_GlitchedSpawSpeed("GlitchedSpawSpeed", Range( 0 , 10)) = 3
		_GlitchesTiling("Glitches Tiling", Range( 0 , 2)) = 0.75
		_Panner1("Panner 1", Float) = -1.5
		_Panner2("Panner 2", Float) = -1.5
		_UVs2TilingxyScalezw("UVs 2 Tiling (xy) Scale (zw)", Vector) = (2,2,5,5)
		_UVs1TilingxyScalezw("UVs 1 Tiling (xy) Scale (zw)", Vector) = (1,1,5,5)
		_DistortionBlend("DistortionBlend", Range( 0 , 1)) = 0.7
		[HideInInspector][NoScaleOffset]_DistortionNormal("DistortionNormal", 2D) = "bump" {}
		_GlitchDisplacementStrenght("Glitch Displacement Strenght", Range( 0 , 1)) = 1
		_RefractionOffset("Refraction Offset", Range( 0 , 0.5)) = 0.05
		[NoScaleOffset]_EmissiveRVertDispMaskG("Emissive(R)VertDispMask(G)", 2D) = "white" {}
		_EmissiveTiling("Emissive Tiling", Vector) = (1,1,0,0)
		_StripesSpeed("StripesSpeed", Float) = -5
		[HDR]_EmissiveColor("Emissive Color", Color) = (6.19,0.91,0.91,0)
		_StripesScale("StripesScale", Float) = 5
		_BaseColor("Base Color", Color) = (0.2941177,0.007843138,0.0509804,0)
		_PulseSpeed("PulseSpeed", Float) = -0.75
		_OverallOpacity("OverallOpacity", Range( 0 , 1)) = 0.1
		_StripesIntensity("StripesIntensity", Range( 0 , 1)) = 0.1
		_MinPulseOpacity("MinPulseOpacity", Range( 0 , 1)) = 0
		[Toggle(_KEYWORD0_ON)] _Keyword0("Keyword 0", Float) = 0
		[Toggle(_USEFRACTIONUUV1_ON)] _UseFractionUUV1("UseFractionUUV 1", Float) = 0
		[Toggle(_USESTEPTIME1_ON)] _UseStepTime1("UseStepTime1", Float) = 0
		[Toggle(_USEVERTEXDISPLACE1_ON)] _UseVertexDisplace1("Use Vertex Displace 1", Float) = 0
		[Toggle(_USEBREATHPULSE_ON)] _UseBreathPulse("Use Breath Pulse", Float) = 0
		[Toggle(_GLOBALOPACITYPULSE_ON)] _GlobalOpacityPulse("Global Opacity Pulse", Float) = 1
		_FresnelScale("FresnelScale", Float) = 5
		[ASEEnd][Toggle(_USEFRESNEL_ON)] _UseFresnel("Use Fresnel", Float) = 0
		[HideInInspector] _texcoord( "", 2D ) = "white" {}


		[HideInInspector]_QueueOffset("_QueueOffset", Float) = 0
        [HideInInspector]_QueueControl("_QueueControl", Float) = -1

        [HideInInspector][NoScaleOffset]unity_Lightmaps("unity_Lightmaps", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset]unity_LightmapsInd("unity_LightmapsInd", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset]unity_ShadowMasks("unity_ShadowMasks", 2DArray) = "" {}

		//_TessPhongStrength( "Tess Phong Strength", Range( 0, 1 ) ) = 0.5
		_TessValue( "Max Tessellation", Range( 1, 32 ) ) = 16
		//_TessMin( "Tess Min Distance", Float ) = 10
		//_TessMax( "Tess Max Distance", Float ) = 25
		//_TessEdgeLength ( "Tess Edge length", Range( 2, 50 ) ) = 16
		//_TessMaxDisp( "Tess Max Displacement", Float ) = 25
	}

	SubShader
	{
		LOD 0

		

		Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Transparent" "Queue"="Transparent" }

		Cull Back
		AlphaToMask Off

		

		HLSLINCLUDE
		#pragma target 5.0
		#pragma prefer_hlslcc gles
		// ensure rendering platforms toggle list is visible

		#ifndef ASE_TESS_FUNCS
		#define ASE_TESS_FUNCS
		float4 FixedTess( float tessValue )
		{
			return tessValue;
		}

		float CalcDistanceTessFactor (float4 vertex, float minDist, float maxDist, float tess, float4x4 o2w, float3 cameraPos )
		{
			float3 wpos = mul(o2w,vertex).xyz;
			float dist = distance (wpos, cameraPos);
			float f = clamp(1.0 - (dist - minDist) / (maxDist - minDist), 0.01, 1.0) * tess;
			return f;
		}

		float4 CalcTriEdgeTessFactors (float3 triVertexFactors)
		{
			float4 tess;
			tess.x = 0.5 * (triVertexFactors.y + triVertexFactors.z);
			tess.y = 0.5 * (triVertexFactors.x + triVertexFactors.z);
			tess.z = 0.5 * (triVertexFactors.x + triVertexFactors.y);
			tess.w = (triVertexFactors.x + triVertexFactors.y + triVertexFactors.z) / 3.0f;
			return tess;
		}

		float CalcEdgeTessFactor (float3 wpos0, float3 wpos1, float edgeLen, float3 cameraPos, float4 scParams )
		{
			float dist = distance (0.5 * (wpos0+wpos1), cameraPos);
			float len = distance(wpos0, wpos1);
			float f = max(len * scParams.y / (edgeLen * dist), 1.0);
			return f;
		}

		float DistanceFromPlane (float3 pos, float4 plane)
		{
			float d = dot (float4(pos,1.0f), plane);
			return d;
		}

		bool WorldViewFrustumCull (float3 wpos0, float3 wpos1, float3 wpos2, float cullEps, float4 planes[6] )
		{
			float4 planeTest;
			planeTest.x = (( DistanceFromPlane(wpos0, planes[0]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos1, planes[0]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos2, planes[0]) > -cullEps) ? 1.0f : 0.0f );
			planeTest.y = (( DistanceFromPlane(wpos0, planes[1]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos1, planes[1]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos2, planes[1]) > -cullEps) ? 1.0f : 0.0f );
			planeTest.z = (( DistanceFromPlane(wpos0, planes[2]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos1, planes[2]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos2, planes[2]) > -cullEps) ? 1.0f : 0.0f );
			planeTest.w = (( DistanceFromPlane(wpos0, planes[3]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos1, planes[3]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos2, planes[3]) > -cullEps) ? 1.0f : 0.0f );
			return !all (planeTest);
		}

		float4 DistanceBasedTess( float4 v0, float4 v1, float4 v2, float tess, float minDist, float maxDist, float4x4 o2w, float3 cameraPos )
		{
			float3 f;
			f.x = CalcDistanceTessFactor (v0,minDist,maxDist,tess,o2w,cameraPos);
			f.y = CalcDistanceTessFactor (v1,minDist,maxDist,tess,o2w,cameraPos);
			f.z = CalcDistanceTessFactor (v2,minDist,maxDist,tess,o2w,cameraPos);

			return CalcTriEdgeTessFactors (f);
		}

		float4 EdgeLengthBasedTess( float4 v0, float4 v1, float4 v2, float edgeLength, float4x4 o2w, float3 cameraPos, float4 scParams )
		{
			float3 pos0 = mul(o2w,v0).xyz;
			float3 pos1 = mul(o2w,v1).xyz;
			float3 pos2 = mul(o2w,v2).xyz;
			float4 tess;
			tess.x = CalcEdgeTessFactor (pos1, pos2, edgeLength, cameraPos, scParams);
			tess.y = CalcEdgeTessFactor (pos2, pos0, edgeLength, cameraPos, scParams);
			tess.z = CalcEdgeTessFactor (pos0, pos1, edgeLength, cameraPos, scParams);
			tess.w = (tess.x + tess.y + tess.z) / 3.0f;
			return tess;
		}

		float4 EdgeLengthBasedTessCull( float4 v0, float4 v1, float4 v2, float edgeLength, float maxDisplacement, float4x4 o2w, float3 cameraPos, float4 scParams, float4 planes[6] )
		{
			float3 pos0 = mul(o2w,v0).xyz;
			float3 pos1 = mul(o2w,v1).xyz;
			float3 pos2 = mul(o2w,v2).xyz;
			float4 tess;

			if (WorldViewFrustumCull(pos0, pos1, pos2, maxDisplacement, planes))
			{
				tess = 0.0f;
			}
			else
			{
				tess.x = CalcEdgeTessFactor (pos1, pos2, edgeLength, cameraPos, scParams);
				tess.y = CalcEdgeTessFactor (pos2, pos0, edgeLength, cameraPos, scParams);
				tess.z = CalcEdgeTessFactor (pos0, pos1, edgeLength, cameraPos, scParams);
				tess.w = (tess.x + tess.y + tess.z) / 3.0f;
			}
			return tess;
		}
		#endif //ASE_TESS_FUNCS
		ENDHLSL

		
		Pass
		{
			
			Name "Forward"
			Tags { "LightMode"="UniversalForwardOnly" }

			Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
			ZWrite On
			ZTest LEqual
			Offset 0 , 0
			ColorMask RGBA

			

			HLSLPROGRAM

			#pragma multi_compile_instancing
			#define _SURFACE_TYPE_TRANSPARENT 1
			#define ASE_TESSELLATION 1
			#pragma require tessellation tessHW
			#pragma hull HullFunction
			#pragma domain DomainFunction
			#define ASE_FIXED_TESSELLATION
			#define ASE_SRP_VERSION -1
			#define REQUIRE_OPAQUE_TEXTURE 1


			#pragma instancing_options renderinglayer

			#pragma multi_compile _ LIGHTMAP_ON
        	#pragma multi_compile _ DIRLIGHTMAP_COMBINED
        	#pragma shader_feature _ _SAMPLE_GI
        	#pragma multi_compile_fragment _ _DBUFFER_MRT1 _DBUFFER_MRT2 _DBUFFER_MRT3
        	#pragma multi_compile_fragment _ DEBUG_DISPLAY
        	#pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION
        	#pragma multi_compile_fragment _ _WRITE_RENDERING_LAYERS

			#pragma vertex vert
			#pragma fragment frag

			#define SHADERPASS SHADERPASS_UNLIT

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DBuffer.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Debug/Debugging3D.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceData.hlsl"

			#define ASE_NEEDS_VERT_POSITION
			#define ASE_NEEDS_VERT_NORMAL
			#define ASE_NEEDS_FRAG_WORLD_POSITION
			#define ASE_NEEDS_FRAG_POSITION
			#pragma shader_feature_local _USEVERTEXDISPLACE1_ON
			#pragma shader_feature_local _USEFRACTIONUUV1_ON
			#pragma shader_feature_local _USESTEPTIME1_ON
			#pragma shader_feature_local _USEFRESNEL_ON
			#pragma shader_feature_local _USEBREATHPULSE_ON
			#pragma shader_feature_local _GLOBALOPACITYPULSE_ON


			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 ase_texcoord : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 clipPos : SV_POSITION;
				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					float3 worldPos : TEXCOORD0;
				#endif
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					float4 shadowCoord : TEXCOORD1;
				#endif
				#ifdef ASE_FOG
					float fogFactor : TEXCOORD2;
				#endif
				float4 ase_texcoord3 : TEXCOORD3;
				float4 ase_texcoord4 : TEXCOORD4;
				float4 ase_texcoord5 : TEXCOORD5;
				float4 ase_texcoord6 : TEXCOORD6;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _EmissiveColor;
			float4 _UVs1TilingxyScalezw;
			float4 _UVs2TilingxyScalezw;
			float4 _BaseColor;
			float2 _EmissiveTiling;
			float _StripesScale;
			float _StripesSpeed;
			float _GlitchedSpawSpeed;
			float _MinPulseOpacity;
			float _PulseSpeed;
			float _FresnelScale;
			float _GlitchesTiling;
			float _RefractionOffset;
			float _DistortionBlend;
			float _Panner2;
			float _Panner1;
			float _GlitchDisplacementStrenght;
			float _OverallOpacity;
			float _StripesIntensity;
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			sampler2D _MaskMap;
			sampler2D _EmissiveRVertDispMaskG;
			sampler2D _DistortionNormal;


			float3 mod2D289( float3 x ) { return x - floor( x * ( 1.0 / 289.0 ) ) * 289.0; }
			float2 mod2D289( float2 x ) { return x - floor( x * ( 1.0 / 289.0 ) ) * 289.0; }
			float3 permute( float3 x ) { return mod2D289( ( ( x * 34.0 ) + 1.0 ) * x ); }
			float snoise( float2 v )
			{
				const float4 C = float4( 0.211324865405187, 0.366025403784439, -0.577350269189626, 0.024390243902439 );
				float2 i = floor( v + dot( v, C.yy ) );
				float2 x0 = v - i + dot( i, C.xx );
				float2 i1;
				i1 = ( x0.x > x0.y ) ? float2( 1.0, 0.0 ) : float2( 0.0, 1.0 );
				float4 x12 = x0.xyxy + C.xxzz;
				x12.xy -= i1;
				i = mod2D289( i );
				float3 p = permute( permute( i.y + float3( 0.0, i1.y, 1.0 ) ) + i.x + float3( 0.0, i1.x, 1.0 ) );
				float3 m = max( 0.5 - float3( dot( x0, x0 ), dot( x12.xy, x12.xy ), dot( x12.zw, x12.zw ) ), 0.0 );
				m = m * m;
				m = m * m;
				float3 x = 2.0 * frac( p * C.www ) - 1.0;
				float3 h = abs( x ) - 0.5;
				float3 ox = floor( x + 0.5 );
				float3 a0 = x - ox;
				m *= 1.79284291400159 - 0.85373472095314 * ( a0 * a0 + h * h );
				float3 g;
				g.x = a0.x * x0.x + h.x * x0.y;
				g.yz = a0.yz * x12.xz + h.yz * x12.yw;
				return 130.0 * dot( m, g );
			}
			
			inline float4 ASE_ComputeGrabScreenPos( float4 pos )
			{
				#if UNITY_UV_STARTS_AT_TOP
				float scale = -1.0;
				#else
				float scale = 1.0;
				#endif
				float4 o = pos;
				o.y = pos.w * 0.5f;
				o.y = ( pos.y - o.y ) * _ProjectionParams.x * scale + o.y;
				return o;
			}
			

			VertexOutput VertexFunction ( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float3 ase_worldPos = TransformObjectToWorld( (v.vertex).xyz );
				float3 ase_worldViewDir = ( _WorldSpaceCameraPos.xyz - ase_worldPos );
				ase_worldViewDir = SafeNormalize( ase_worldViewDir );
				float3 normalizeResult177 = normalize( cross( ase_worldViewDir , float3( 0,1,0 ) ) );
				float mulTime17 = _TimeParameters.x * 0.25;
				float4 unityObjectToClipPos96 = TransformWorldToHClip(TransformObjectToWorld(v.vertex.xyz));
				float4 computeScreenPos97 = ComputeScreenPos( unityObjectToClipPos96 );
				computeScreenPos97 = computeScreenPos97 / computeScreenPos97.w;
				computeScreenPos97.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? computeScreenPos97.z : computeScreenPos97.z* 0.5 + 0.5;
				float4 unityObjectToClipPos102 = TransformWorldToHClip(TransformObjectToWorld(float3(0,0,0)));
				float4 computeScreenPos103 = ComputeScreenPos( unityObjectToClipPos102 );
				computeScreenPos103 = computeScreenPos103 / computeScreenPos103.w;
				computeScreenPos103.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? computeScreenPos103.z : computeScreenPos103.z* 0.5 + 0.5;
				float4 transform109 = mul(GetObjectToWorldMatrix(),float4( 0,0,0,1 ));
				float4 break112 = ( ( ( computeScreenPos97 * _GlitchesTiling ) - ( _GlitchesTiling * computeScreenPos103 ) ) * distance( ( float4( _WorldSpaceCameraPos , 0.0 ) - transform109 ) , float4( 0,0,0,0 ) ) );
				float4 appendResult113 = (float4(( break112.x * ( _ScreenParams.x / _ScreenParams.y ) ) , break112.y , break112.z , break112.w));
				float4 FixedScreenUVs117 = appendResult113;
				float2 temp_output_14_0 = (FixedScreenUVs117).xy;
				float temp_output_25_0 = frac( _TimeParameters.y );
				float RandomSwitch130 = step( ( temp_output_25_0 * 5.0 ) , 0.5 );
				float lerpResult32 = lerp( 0.85 , 1.0 , RandomSwitch130);
				float2 panner15 = ( mulTime17 * float2( 0,-0.5 ) + (temp_output_14_0*lerpResult32 + 0.0));
				float4 tex2DNode10 = tex2Dlod( _MaskMap, float4( panner15, 0, 0.0) );
				float lerpResult64 = lerp( 0.15 , 0.1 , RandomSwitch130);
				float mulTime19 = _TimeParameters.x * 0.5;
				float lerpResult35 = lerp( 0.75 , 1.0 , RandomSwitch130);
				float2 panner20 = ( mulTime19 * float2( 0,-0.5 ) + (temp_output_14_0*lerpResult35 + 0.0));
				float4 tex2DNode22 = tex2Dlod( _MaskMap, float4( panner20, 0, 0.0) );
				float RandomSwitch231 = step( temp_output_25_0 , 0.5 );
				float lerpResult70 = lerp( ( tex2DNode10.r * -lerpResult64 ) , ( lerpResult64 * tex2DNode22.r ) , RandomSwitch231);
				float SmallGlitches85 = lerpResult70;
				float temp_output_50_0 = step( v.vertex.xyz.y , ( _TimeParameters.y * 0.1 ) );
				float lerpResult58 = lerp( -0.075 , 0.075 , temp_output_50_0);
				float temp_output_55_0 = step( ( frac( _TimeParameters.y ) * 20.0 ) , 0.9 );
				float BigGlitches60 = ( lerpResult58 * temp_output_55_0 );
				float CombinedGlitches90 = ( SmallGlitches85 + BigGlitches60 );
				float2 uv_EmissiveRVertDispMaskG258 = v.ase_texcoord.xy;
				float4 _SpeedxStrenghtyFractUVz = float4(0.5,0.08,4,4);
				float mulTime245 = _TimeParameters.x * _SpeedxStrenghtyFractUVz.x;
				#ifdef _USESTEPTIME1_ON
				float staticSwitch247 = floor( mulTime245 );
				#else
				float staticSwitch247 = mulTime245;
				#endif
				float2 panner252 = ( staticSwitch247 * float2( -1,-1 ) + (FixedScreenUVs117).xy);
				float simplePerlin2D253 = snoise( panner252*5.0 );
				simplePerlin2D253 = simplePerlin2D253*0.5 + 0.5;
				float2 texCoord248 = v.ase_texcoord.xy * float2( 1,1 ) + float2( 0,0 );
				float pixelWidth249 =  1.0f / _SpeedxStrenghtyFractUVz.z;
				float pixelHeight249 = 1.0f / _SpeedxStrenghtyFractUVz.w;
				half2 pixelateduv249 = half2((int)(texCoord248.x / pixelWidth249) * pixelWidth249, (int)(texCoord248.y / pixelHeight249) * pixelHeight249);
				float2 panner250 = ( staticSwitch247 * float2( 1,1 ) + pixelateduv249);
				float simplePerlin2D251 = snoise( panner250*5.0 );
				simplePerlin2D251 = simplePerlin2D251*0.5 + 0.5;
				#ifdef _USEFRACTIONUUV1_ON
				float staticSwitch256 = simplePerlin2D251;
				#else
				float staticSwitch256 = simplePerlin2D253;
				#endif
				#ifdef _USEVERTEXDISPLACE1_ON
				float3 staticSwitch261 = ( v.ase_normal * ( tex2Dlod( _EmissiveRVertDispMaskG, float4( uv_EmissiveRVertDispMaskG258, 0, 0.0) ).g * staticSwitch256 * _SpeedxStrenghtyFractUVz.y ) );
				#else
				float3 staticSwitch261 = float3( 0,0,0 );
				#endif
				float3 VertNormalDisplace262 = staticSwitch261;
				float3 temp_output_310_0 = ( ( -normalizeResult177 * ( CombinedGlitches90 * _GlitchDisplacementStrenght ) ) + VertNormalDisplace262 );
				
				float3 normalizeResult323 = normalize( temp_output_310_0 );
				
				float4 ase_clipPos = TransformObjectToHClip((v.vertex).xyz);
				float4 screenPos = ComputeScreenPos(ase_clipPos);
				o.ase_texcoord3 = screenPos;
				float3 ase_worldNormal = TransformObjectToWorldNormal(v.ase_normal);
				o.ase_texcoord6.xyz = ase_worldNormal;
				
				o.ase_texcoord4 = v.vertex;
				o.ase_texcoord5.xy = v.ase_texcoord.xy;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord5.zw = 0;
				o.ase_texcoord6.w = 0;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = temp_output_310_0;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif

				v.ase_normal = normalizeResult323;

				float3 positionWS = TransformObjectToWorld( v.vertex.xyz );
				float4 positionCS = TransformWorldToHClip( positionWS );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					o.worldPos = positionWS;
				#endif

				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					VertexPositionInputs vertexInput = (VertexPositionInputs)0;
					vertexInput.positionWS = positionWS;
					vertexInput.positionCS = positionCS;
					o.shadowCoord = GetShadowCoord( vertexInput );
				#endif

				#ifdef ASE_FOG
					o.fogFactor = ComputeFogFactor( positionCS.z );
				#endif

				o.clipPos = positionCS;

				return o;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 ase_normal : NORMAL;
				float4 ase_texcoord : TEXCOORD0;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.vertex;
				o.ase_normal = v.ase_normal;
				o.ase_texcoord = v.ase_texcoord;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
			   return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.ase_normal = patch[0].ase_normal * bary.x + patch[1].ase_normal * bary.y + patch[2].ase_normal * bary.z;
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.vertex.xyz - patch[i].ase_normal * (dot(o.vertex.xyz, patch[i].ase_normal) - dot(patch[i].vertex.xyz, patch[i].ase_normal));
				float phongStrength = _TessPhongStrength;
				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			half4 frag ( VertexOutput IN
				#ifdef _WRITE_RENDERING_LAYERS
				, out float4 outRenderingLayers : SV_Target1
				#endif
				 ) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID( IN );
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( IN );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					float3 WorldPosition = IN.worldPos;
				#endif

				float4 ShadowCoords = float4( 0, 0, 0, 0 );

				#if defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
						ShadowCoords = IN.shadowCoord;
					#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
						ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
					#endif
				#endif

				float4 screenPos = IN.ase_texcoord3;
				float4 ase_grabScreenPos = ASE_ComputeGrabScreenPos( screenPos );
				float4 ase_grabScreenPosNorm = ase_grabScreenPos / ase_grabScreenPos.w;
				float2 appendResult156 = (float2(ase_grabScreenPosNorm.r , ase_grabScreenPosNorm.g));
				float2 temp_output_127_0 = (WorldPosition).xz;
				float mulTime121 = _TimeParameters.x * 0.05;
				float2 appendResult135 = (float2(_UVs1TilingxyScalezw.x , _UVs1TilingxyScalezw.y));
				float2 appendResult136 = (float2(_UVs1TilingxyScalezw.z , _UVs1TilingxyScalezw.w));
				float2 UVs1141 = ( ( ( temp_output_127_0 + ( mulTime121 * _Panner1 ) ) * appendResult135 ) / appendResult136 );
				float2 appendResult137 = (float2(_UVs2TilingxyScalezw.x , _UVs2TilingxyScalezw.y));
				float2 appendResult138 = (float2(_UVs2TilingxyScalezw.z , _UVs2TilingxyScalezw.w));
				float2 UVs2144 = ( ( ( temp_output_127_0 + ( mulTime121 * _Panner2 ) ) * appendResult137 ) / appendResult138 );
				float3 lerpResult150 = lerp( UnpackNormalScale( tex2D( _DistortionNormal, UVs1141 ), 1.0f ) , UnpackNormalScale( tex2D( _DistortionNormal, UVs2144 ), 1.0f ) , _DistortionBlend);
				float3 Distortion152 = lerpResult150;
				float2 ScreenUV163 = ( appendResult156 - ( (Distortion152).xy * 0.1 ) );
				float mulTime17 = _TimeParameters.x * 0.25;
				float4 unityObjectToClipPos96 = TransformWorldToHClip(TransformObjectToWorld(IN.ase_texcoord4.xyz));
				float4 computeScreenPos97 = ComputeScreenPos( unityObjectToClipPos96 );
				computeScreenPos97 = computeScreenPos97 / computeScreenPos97.w;
				computeScreenPos97.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? computeScreenPos97.z : computeScreenPos97.z* 0.5 + 0.5;
				float4 unityObjectToClipPos102 = TransformWorldToHClip(TransformObjectToWorld(float3(0,0,0)));
				float4 computeScreenPos103 = ComputeScreenPos( unityObjectToClipPos102 );
				computeScreenPos103 = computeScreenPos103 / computeScreenPos103.w;
				computeScreenPos103.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? computeScreenPos103.z : computeScreenPos103.z* 0.5 + 0.5;
				float4 transform109 = mul(GetObjectToWorldMatrix(),float4( 0,0,0,1 ));
				float4 break112 = ( ( ( computeScreenPos97 * _GlitchesTiling ) - ( _GlitchesTiling * computeScreenPos103 ) ) * distance( ( float4( _WorldSpaceCameraPos , 0.0 ) - transform109 ) , float4( 0,0,0,0 ) ) );
				float4 appendResult113 = (float4(( break112.x * ( _ScreenParams.x / _ScreenParams.y ) ) , break112.y , break112.z , break112.w));
				float4 FixedScreenUVs117 = appendResult113;
				float2 temp_output_14_0 = (FixedScreenUVs117).xy;
				float temp_output_25_0 = frac( _TimeParameters.y );
				float RandomSwitch130 = step( ( temp_output_25_0 * 5.0 ) , 0.5 );
				float lerpResult32 = lerp( 0.85 , 1.0 , RandomSwitch130);
				float2 panner15 = ( mulTime17 * float2( 0,-0.5 ) + (temp_output_14_0*lerpResult32 + 0.0));
				float4 tex2DNode10 = tex2D( _MaskMap, panner15 );
				float lerpResult64 = lerp( 0.15 , 0.1 , RandomSwitch130);
				float mulTime19 = _TimeParameters.x * 0.5;
				float lerpResult35 = lerp( 0.75 , 1.0 , RandomSwitch130);
				float2 panner20 = ( mulTime19 * float2( 0,-0.5 ) + (temp_output_14_0*lerpResult35 + 0.0));
				float4 tex2DNode22 = tex2D( _MaskMap, panner20 );
				float RandomSwitch231 = step( temp_output_25_0 , 0.5 );
				float lerpResult70 = lerp( ( tex2DNode10.r * -lerpResult64 ) , ( lerpResult64 * tex2DNode22.r ) , RandomSwitch231);
				float SmallGlitches85 = lerpResult70;
				float temp_output_50_0 = step( IN.ase_texcoord4.xyz.y , ( _TimeParameters.y * 0.1 ) );
				float lerpResult58 = lerp( -0.075 , 0.075 , temp_output_50_0);
				float temp_output_55_0 = step( ( frac( _TimeParameters.y ) * 20.0 ) , 0.9 );
				float BigGlitches60 = ( lerpResult58 * temp_output_55_0 );
				float CombinedGlitches90 = ( SmallGlitches85 + BigGlitches60 );
				float3 ase_worldViewDir = ( _WorldSpaceCameraPos.xyz - WorldPosition );
				ase_worldViewDir = SafeNormalize( ase_worldViewDir );
				float3 normalizeResult177 = normalize( cross( ase_worldViewDir , float3( 0,1,0 ) ) );
				float4 fetchOpaqueVal165 = float4( SHADERGRAPH_SAMPLE_SCENE_COLOR( (ScreenUV163*1.0 + -( CombinedGlitches90 * _RefractionOffset * -normalizeResult177 ).xy) ), 1.0 );
				float2 texCoord195 = IN.ase_texcoord5.xy * _EmissiveTiling + float2( 0,0 );
				ase_worldViewDir = normalize(ase_worldViewDir);
				float3 ase_worldNormal = IN.ase_texcoord6.xyz;
				float fresnelNdotV273 = dot( ase_worldNormal, ase_worldViewDir );
				float fresnelNode273 = ( 0.0 + _FresnelScale * pow( 1.0 - fresnelNdotV273, 5.0 ) );
				float smoothstepResult275 = smoothstep( (0.0 + (0.0 - 0.0) * (1.0 - 0.0) / (1.0 - 0.0)) , 1.0 , fresnelNode273);
				#ifdef _USEFRESNEL_ON
				float staticSwitch276 = smoothstepResult275;
				#else
				float staticSwitch276 = 0.0;
				#endif
				float2 appendResult222 = (float2(0.0 , _PulseSpeed));
				float2 temp_output_215_0 = (FixedScreenUVs117).xy;
				float2 panner221 = ( _TimeParameters.x * appendResult222 + temp_output_215_0);
				#ifdef _USEBREATHPULSE_ON
				float staticSwitch264 = abs( _TimeParameters.y );
				#else
				float staticSwitch264 = tex2D( _MaskMap, panner221 ).g;
				#endif
				float temp_output_230_0 = (_MinPulseOpacity + (staticSwitch264 - 0.0) * (1.0 - _MinPulseOpacity) / (1.0 - 0.0));
				#ifdef _KEYWORD0_ON
				float staticSwitch268 = 1.0;
				#else
				float staticSwitch268 = temp_output_230_0;
				#endif
				float PulseMask233 = staticSwitch268;
				float lerpResult200 = lerp( _BaseColor.r , _EmissiveColor.r , ( saturate( ( tex2D( _EmissiveRVertDispMaskG, texCoord195 ).r + staticSwitch276 ) ) * PulseMask233 * 1.0 ));
				float mulTime36 = _TimeParameters.x * 1.5;
				float mulTime37 = _TimeParameters.x * 2.0;
				float mulTime39 = _TimeParameters.x * 2.2;
				float mulTime38 = _TimeParameters.x * 3.0;
				float SmallGlitchesSpawn48 = step( frac( ( sin( mulTime36 ) * sin( mulTime37 ) * sin( mulTime39 ) * sin( mulTime38 ) * _GlitchedSpawSpeed ) ) , 0.1 );
				float lerpResult79 = lerp( tex2DNode10.r , tex2DNode22.r , RandomSwitch231);
				float SmallGlitchesMask83 = ( SmallGlitchesSpawn48 * lerpResult79 );
				float BigGlitchesMask61 = ( temp_output_50_0 * temp_output_55_0 );
				float temp_output_191_0 = ( saturate( ( SmallGlitchesMask83 + BigGlitchesMask61 ) ) * 0.075 );
				float2 appendResult194 = (float2(-temp_output_191_0 , 0.0));
				float2 texCoord196 = IN.ase_texcoord5.xy * _EmissiveTiling + appendResult194;
				float lerpResult201 = lerp( _BaseColor.g , _EmissiveColor.g , ( saturate( ( tex2D( _EmissiveRVertDispMaskG, texCoord196 ).r + staticSwitch276 ) ) * PulseMask233 * 1.0 ));
				float2 appendResult193 = (float2(temp_output_191_0 , 0.0));
				float2 texCoord197 = IN.ase_texcoord5.xy * _EmissiveTiling + appendResult193;
				float lerpResult202 = lerp( _BaseColor.b , _EmissiveColor.b , ( saturate( ( tex2D( _EmissiveRVertDispMaskG, texCoord197 ).r + staticSwitch276 ) ) * PulseMask233 * 1.0 ));
				float3 appendResult204 = (float3(lerpResult200 , lerpResult201 , lerpResult202));
				float3 EmissionColor205 = appendResult204;
				float2 appendResult218 = (float2(0.0 , _StripesSpeed));
				float2 panner216 = ( _TimeParameters.x * appendResult218 + (temp_output_215_0*_StripesScale + 0.0));
				float clampResult228 = clamp( ( _OverallOpacity - _StripesIntensity ) , 0.0 , _OverallOpacity );
				float temp_output_229_0 = (clampResult228 + (tex2D( _MaskMap, panner216 ).b - 0.0) * (_OverallOpacity - clampResult228) / (1.0 - 0.0));
				#ifdef _GLOBALOPACITYPULSE_ON
				float staticSwitch270 = ( temp_output_229_0 * temp_output_230_0 );
				#else
				float staticSwitch270 = temp_output_229_0;
				#endif
				float StripeMask234 = staticSwitch270;
				float4 lerpResult210 = lerp( fetchOpaqueVal165 , float4( EmissionColor205 , 0.0 ) , StripeMask234);
				
				float3 BakedAlbedo = 0;
				float3 BakedEmission = 0;
				float3 Color = lerpResult210.rgb;
				float Alpha = 1;
				float AlphaClipThreshold = 0.5;
				float AlphaClipThresholdShadow = 0.5;

				#ifdef _ALPHATEST_ON
					clip( Alpha - AlphaClipThreshold );
				#endif

				#if defined(_DBUFFER)
					ApplyDecalToBaseColor(IN.clipPos, Color);
				#endif

				#if defined(_ALPHAPREMULTIPLY_ON)
				Color *= Alpha;
				#endif

				#ifdef LOD_FADE_CROSSFADE
					LODDitheringTransition( IN.clipPos.xyz, unity_LODFade.x );
				#endif

				#ifdef ASE_FOG
					Color = MixFog( Color, IN.fogFactor );
				#endif

				#ifdef _WRITE_RENDERING_LAYERS
					uint renderingLayers = GetMeshRenderingLayer();
					outRenderingLayers = float4( EncodeMeshRenderingLayer( renderingLayers ), 0, 0, 0 );
				#endif

				return half4( Color, Alpha );
			}
			ENDHLSL
		}

		
		Pass
		{
			
			Name "ShadowCaster"
			Tags { "LightMode"="ShadowCaster" }

			ZWrite On
			ZTest LEqual
			AlphaToMask Off
			ColorMask 0

			HLSLPROGRAM

			#pragma multi_compile_instancing
			#define _SURFACE_TYPE_TRANSPARENT 1
			#define ASE_TESSELLATION 1
			#pragma require tessellation tessHW
			#pragma hull HullFunction
			#pragma domain DomainFunction
			#define ASE_FIXED_TESSELLATION
			#define ASE_SRP_VERSION -1


			#pragma vertex vert
			#pragma fragment frag

			#pragma multi_compile _ _CASTING_PUNCTUAL_LIGHT_SHADOW

			#define SHADERPASS SHADERPASS_SHADOWCASTER

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"

			#define ASE_NEEDS_VERT_POSITION
			#define ASE_NEEDS_VERT_NORMAL
			#pragma shader_feature_local _USEVERTEXDISPLACE1_ON
			#pragma shader_feature_local _USEFRACTIONUUV1_ON
			#pragma shader_feature_local _USESTEPTIME1_ON


			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 ase_texcoord : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 clipPos : SV_POSITION;
				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					float3 worldPos : TEXCOORD0;
				#endif
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					float4 shadowCoord : TEXCOORD1;
				#endif
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _EmissiveColor;
			float4 _UVs1TilingxyScalezw;
			float4 _UVs2TilingxyScalezw;
			float4 _BaseColor;
			float2 _EmissiveTiling;
			float _StripesScale;
			float _StripesSpeed;
			float _GlitchedSpawSpeed;
			float _MinPulseOpacity;
			float _PulseSpeed;
			float _FresnelScale;
			float _GlitchesTiling;
			float _RefractionOffset;
			float _DistortionBlend;
			float _Panner2;
			float _Panner1;
			float _GlitchDisplacementStrenght;
			float _OverallOpacity;
			float _StripesIntensity;
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			sampler2D _MaskMap;
			sampler2D _EmissiveRVertDispMaskG;


			float3 mod2D289( float3 x ) { return x - floor( x * ( 1.0 / 289.0 ) ) * 289.0; }
			float2 mod2D289( float2 x ) { return x - floor( x * ( 1.0 / 289.0 ) ) * 289.0; }
			float3 permute( float3 x ) { return mod2D289( ( ( x * 34.0 ) + 1.0 ) * x ); }
			float snoise( float2 v )
			{
				const float4 C = float4( 0.211324865405187, 0.366025403784439, -0.577350269189626, 0.024390243902439 );
				float2 i = floor( v + dot( v, C.yy ) );
				float2 x0 = v - i + dot( i, C.xx );
				float2 i1;
				i1 = ( x0.x > x0.y ) ? float2( 1.0, 0.0 ) : float2( 0.0, 1.0 );
				float4 x12 = x0.xyxy + C.xxzz;
				x12.xy -= i1;
				i = mod2D289( i );
				float3 p = permute( permute( i.y + float3( 0.0, i1.y, 1.0 ) ) + i.x + float3( 0.0, i1.x, 1.0 ) );
				float3 m = max( 0.5 - float3( dot( x0, x0 ), dot( x12.xy, x12.xy ), dot( x12.zw, x12.zw ) ), 0.0 );
				m = m * m;
				m = m * m;
				float3 x = 2.0 * frac( p * C.www ) - 1.0;
				float3 h = abs( x ) - 0.5;
				float3 ox = floor( x + 0.5 );
				float3 a0 = x - ox;
				m *= 1.79284291400159 - 0.85373472095314 * ( a0 * a0 + h * h );
				float3 g;
				g.x = a0.x * x0.x + h.x * x0.y;
				g.yz = a0.yz * x12.xz + h.yz * x12.yw;
				return 130.0 * dot( m, g );
			}
			

			float3 _LightDirection;
			float3 _LightPosition;

			VertexOutput VertexFunction( VertexInput v )
			{
				VertexOutput o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO( o );

				float3 ase_worldPos = TransformObjectToWorld( (v.vertex).xyz );
				float3 ase_worldViewDir = ( _WorldSpaceCameraPos.xyz - ase_worldPos );
				ase_worldViewDir = SafeNormalize( ase_worldViewDir );
				float3 normalizeResult177 = normalize( cross( ase_worldViewDir , float3( 0,1,0 ) ) );
				float mulTime17 = _TimeParameters.x * 0.25;
				float4 unityObjectToClipPos96 = TransformWorldToHClip(TransformObjectToWorld(v.vertex.xyz));
				float4 computeScreenPos97 = ComputeScreenPos( unityObjectToClipPos96 );
				computeScreenPos97 = computeScreenPos97 / computeScreenPos97.w;
				computeScreenPos97.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? computeScreenPos97.z : computeScreenPos97.z* 0.5 + 0.5;
				float4 unityObjectToClipPos102 = TransformWorldToHClip(TransformObjectToWorld(float3(0,0,0)));
				float4 computeScreenPos103 = ComputeScreenPos( unityObjectToClipPos102 );
				computeScreenPos103 = computeScreenPos103 / computeScreenPos103.w;
				computeScreenPos103.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? computeScreenPos103.z : computeScreenPos103.z* 0.5 + 0.5;
				float4 transform109 = mul(GetObjectToWorldMatrix(),float4( 0,0,0,1 ));
				float4 break112 = ( ( ( computeScreenPos97 * _GlitchesTiling ) - ( _GlitchesTiling * computeScreenPos103 ) ) * distance( ( float4( _WorldSpaceCameraPos , 0.0 ) - transform109 ) , float4( 0,0,0,0 ) ) );
				float4 appendResult113 = (float4(( break112.x * ( _ScreenParams.x / _ScreenParams.y ) ) , break112.y , break112.z , break112.w));
				float4 FixedScreenUVs117 = appendResult113;
				float2 temp_output_14_0 = (FixedScreenUVs117).xy;
				float temp_output_25_0 = frac( _TimeParameters.y );
				float RandomSwitch130 = step( ( temp_output_25_0 * 5.0 ) , 0.5 );
				float lerpResult32 = lerp( 0.85 , 1.0 , RandomSwitch130);
				float2 panner15 = ( mulTime17 * float2( 0,-0.5 ) + (temp_output_14_0*lerpResult32 + 0.0));
				float4 tex2DNode10 = tex2Dlod( _MaskMap, float4( panner15, 0, 0.0) );
				float lerpResult64 = lerp( 0.15 , 0.1 , RandomSwitch130);
				float mulTime19 = _TimeParameters.x * 0.5;
				float lerpResult35 = lerp( 0.75 , 1.0 , RandomSwitch130);
				float2 panner20 = ( mulTime19 * float2( 0,-0.5 ) + (temp_output_14_0*lerpResult35 + 0.0));
				float4 tex2DNode22 = tex2Dlod( _MaskMap, float4( panner20, 0, 0.0) );
				float RandomSwitch231 = step( temp_output_25_0 , 0.5 );
				float lerpResult70 = lerp( ( tex2DNode10.r * -lerpResult64 ) , ( lerpResult64 * tex2DNode22.r ) , RandomSwitch231);
				float SmallGlitches85 = lerpResult70;
				float temp_output_50_0 = step( v.vertex.xyz.y , ( _TimeParameters.y * 0.1 ) );
				float lerpResult58 = lerp( -0.075 , 0.075 , temp_output_50_0);
				float temp_output_55_0 = step( ( frac( _TimeParameters.y ) * 20.0 ) , 0.9 );
				float BigGlitches60 = ( lerpResult58 * temp_output_55_0 );
				float CombinedGlitches90 = ( SmallGlitches85 + BigGlitches60 );
				float2 uv_EmissiveRVertDispMaskG258 = v.ase_texcoord.xy;
				float4 _SpeedxStrenghtyFractUVz = float4(0.5,0.08,4,4);
				float mulTime245 = _TimeParameters.x * _SpeedxStrenghtyFractUVz.x;
				#ifdef _USESTEPTIME1_ON
				float staticSwitch247 = floor( mulTime245 );
				#else
				float staticSwitch247 = mulTime245;
				#endif
				float2 panner252 = ( staticSwitch247 * float2( -1,-1 ) + (FixedScreenUVs117).xy);
				float simplePerlin2D253 = snoise( panner252*5.0 );
				simplePerlin2D253 = simplePerlin2D253*0.5 + 0.5;
				float2 texCoord248 = v.ase_texcoord.xy * float2( 1,1 ) + float2( 0,0 );
				float pixelWidth249 =  1.0f / _SpeedxStrenghtyFractUVz.z;
				float pixelHeight249 = 1.0f / _SpeedxStrenghtyFractUVz.w;
				half2 pixelateduv249 = half2((int)(texCoord248.x / pixelWidth249) * pixelWidth249, (int)(texCoord248.y / pixelHeight249) * pixelHeight249);
				float2 panner250 = ( staticSwitch247 * float2( 1,1 ) + pixelateduv249);
				float simplePerlin2D251 = snoise( panner250*5.0 );
				simplePerlin2D251 = simplePerlin2D251*0.5 + 0.5;
				#ifdef _USEFRACTIONUUV1_ON
				float staticSwitch256 = simplePerlin2D251;
				#else
				float staticSwitch256 = simplePerlin2D253;
				#endif
				#ifdef _USEVERTEXDISPLACE1_ON
				float3 staticSwitch261 = ( v.ase_normal * ( tex2Dlod( _EmissiveRVertDispMaskG, float4( uv_EmissiveRVertDispMaskG258, 0, 0.0) ).g * staticSwitch256 * _SpeedxStrenghtyFractUVz.y ) );
				#else
				float3 staticSwitch261 = float3( 0,0,0 );
				#endif
				float3 VertNormalDisplace262 = staticSwitch261;
				float3 temp_output_310_0 = ( ( -normalizeResult177 * ( CombinedGlitches90 * _GlitchDisplacementStrenght ) ) + VertNormalDisplace262 );
				
				float3 normalizeResult323 = normalize( temp_output_310_0 );
				

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = temp_output_310_0;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif

				v.ase_normal = normalizeResult323;

				float3 positionWS = TransformObjectToWorld( v.vertex.xyz );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					o.worldPos = positionWS;
				#endif

				float3 normalWS = TransformObjectToWorldDir( v.ase_normal );

				#if _CASTING_PUNCTUAL_LIGHT_SHADOW
					float3 lightDirectionWS = normalize(_LightPosition - positionWS);
				#else
					float3 lightDirectionWS = _LightDirection;
				#endif

				float4 clipPos = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, lightDirectionWS));

				#if UNITY_REVERSED_Z
					clipPos.z = min(clipPos.z, UNITY_NEAR_CLIP_VALUE);
				#else
					clipPos.z = max(clipPos.z, UNITY_NEAR_CLIP_VALUE);
				#endif

				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					VertexPositionInputs vertexInput = (VertexPositionInputs)0;
					vertexInput.positionWS = positionWS;
					vertexInput.positionCS = clipPos;
					o.shadowCoord = GetShadowCoord( vertexInput );
				#endif

				o.clipPos = clipPos;

				return o;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 ase_normal : NORMAL;
				float4 ase_texcoord : TEXCOORD0;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.vertex;
				o.ase_normal = v.ase_normal;
				o.ase_texcoord = v.ase_texcoord;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
			   return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.ase_normal = patch[0].ase_normal * bary.x + patch[1].ase_normal * bary.y + patch[2].ase_normal * bary.z;
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.vertex.xyz - patch[i].ase_normal * (dot(o.vertex.xyz, patch[i].ase_normal) - dot(patch[i].vertex.xyz, patch[i].ase_normal));
				float phongStrength = _TessPhongStrength;
				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			half4 frag(VertexOutput IN  ) : SV_TARGET
			{
				UNITY_SETUP_INSTANCE_ID( IN );
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( IN );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					float3 WorldPosition = IN.worldPos;
				#endif

				float4 ShadowCoords = float4( 0, 0, 0, 0 );

				#if defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
						ShadowCoords = IN.shadowCoord;
					#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
						ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
					#endif
				#endif

				

				float Alpha = 1;
				float AlphaClipThreshold = 0.5;
				float AlphaClipThresholdShadow = 0.5;

				#ifdef _ALPHATEST_ON
					#ifdef _ALPHATEST_SHADOW_ON
						clip(Alpha - AlphaClipThresholdShadow);
					#else
						clip(Alpha - AlphaClipThreshold);
					#endif
				#endif

				#ifdef LOD_FADE_CROSSFADE
					LODDitheringTransition( IN.clipPos.xyz, unity_LODFade.x );
				#endif
				return 0;
			}
			ENDHLSL
		}

		
		Pass
		{
			
			Name "DepthOnly"
			Tags { "LightMode"="DepthOnly" }

			ZWrite On
			ColorMask 0
			AlphaToMask Off

			HLSLPROGRAM

			#pragma multi_compile_instancing
			#define _SURFACE_TYPE_TRANSPARENT 1
			#define ASE_TESSELLATION 1
			#pragma require tessellation tessHW
			#pragma hull HullFunction
			#pragma domain DomainFunction
			#define ASE_FIXED_TESSELLATION
			#define ASE_SRP_VERSION -1


			#pragma vertex vert
			#pragma fragment frag

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"

			#define ASE_NEEDS_VERT_POSITION
			#define ASE_NEEDS_VERT_NORMAL
			#pragma shader_feature_local _USEVERTEXDISPLACE1_ON
			#pragma shader_feature_local _USEFRACTIONUUV1_ON
			#pragma shader_feature_local _USESTEPTIME1_ON


			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 ase_texcoord : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 clipPos : SV_POSITION;
				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				float3 worldPos : TEXCOORD0;
				#endif
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
				float4 shadowCoord : TEXCOORD1;
				#endif
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _EmissiveColor;
			float4 _UVs1TilingxyScalezw;
			float4 _UVs2TilingxyScalezw;
			float4 _BaseColor;
			float2 _EmissiveTiling;
			float _StripesScale;
			float _StripesSpeed;
			float _GlitchedSpawSpeed;
			float _MinPulseOpacity;
			float _PulseSpeed;
			float _FresnelScale;
			float _GlitchesTiling;
			float _RefractionOffset;
			float _DistortionBlend;
			float _Panner2;
			float _Panner1;
			float _GlitchDisplacementStrenght;
			float _OverallOpacity;
			float _StripesIntensity;
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			sampler2D _MaskMap;
			sampler2D _EmissiveRVertDispMaskG;


			float3 mod2D289( float3 x ) { return x - floor( x * ( 1.0 / 289.0 ) ) * 289.0; }
			float2 mod2D289( float2 x ) { return x - floor( x * ( 1.0 / 289.0 ) ) * 289.0; }
			float3 permute( float3 x ) { return mod2D289( ( ( x * 34.0 ) + 1.0 ) * x ); }
			float snoise( float2 v )
			{
				const float4 C = float4( 0.211324865405187, 0.366025403784439, -0.577350269189626, 0.024390243902439 );
				float2 i = floor( v + dot( v, C.yy ) );
				float2 x0 = v - i + dot( i, C.xx );
				float2 i1;
				i1 = ( x0.x > x0.y ) ? float2( 1.0, 0.0 ) : float2( 0.0, 1.0 );
				float4 x12 = x0.xyxy + C.xxzz;
				x12.xy -= i1;
				i = mod2D289( i );
				float3 p = permute( permute( i.y + float3( 0.0, i1.y, 1.0 ) ) + i.x + float3( 0.0, i1.x, 1.0 ) );
				float3 m = max( 0.5 - float3( dot( x0, x0 ), dot( x12.xy, x12.xy ), dot( x12.zw, x12.zw ) ), 0.0 );
				m = m * m;
				m = m * m;
				float3 x = 2.0 * frac( p * C.www ) - 1.0;
				float3 h = abs( x ) - 0.5;
				float3 ox = floor( x + 0.5 );
				float3 a0 = x - ox;
				m *= 1.79284291400159 - 0.85373472095314 * ( a0 * a0 + h * h );
				float3 g;
				g.x = a0.x * x0.x + h.x * x0.y;
				g.yz = a0.yz * x12.xz + h.yz * x12.yw;
				return 130.0 * dot( m, g );
			}
			

			VertexOutput VertexFunction( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float3 ase_worldPos = TransformObjectToWorld( (v.vertex).xyz );
				float3 ase_worldViewDir = ( _WorldSpaceCameraPos.xyz - ase_worldPos );
				ase_worldViewDir = SafeNormalize( ase_worldViewDir );
				float3 normalizeResult177 = normalize( cross( ase_worldViewDir , float3( 0,1,0 ) ) );
				float mulTime17 = _TimeParameters.x * 0.25;
				float4 unityObjectToClipPos96 = TransformWorldToHClip(TransformObjectToWorld(v.vertex.xyz));
				float4 computeScreenPos97 = ComputeScreenPos( unityObjectToClipPos96 );
				computeScreenPos97 = computeScreenPos97 / computeScreenPos97.w;
				computeScreenPos97.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? computeScreenPos97.z : computeScreenPos97.z* 0.5 + 0.5;
				float4 unityObjectToClipPos102 = TransformWorldToHClip(TransformObjectToWorld(float3(0,0,0)));
				float4 computeScreenPos103 = ComputeScreenPos( unityObjectToClipPos102 );
				computeScreenPos103 = computeScreenPos103 / computeScreenPos103.w;
				computeScreenPos103.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? computeScreenPos103.z : computeScreenPos103.z* 0.5 + 0.5;
				float4 transform109 = mul(GetObjectToWorldMatrix(),float4( 0,0,0,1 ));
				float4 break112 = ( ( ( computeScreenPos97 * _GlitchesTiling ) - ( _GlitchesTiling * computeScreenPos103 ) ) * distance( ( float4( _WorldSpaceCameraPos , 0.0 ) - transform109 ) , float4( 0,0,0,0 ) ) );
				float4 appendResult113 = (float4(( break112.x * ( _ScreenParams.x / _ScreenParams.y ) ) , break112.y , break112.z , break112.w));
				float4 FixedScreenUVs117 = appendResult113;
				float2 temp_output_14_0 = (FixedScreenUVs117).xy;
				float temp_output_25_0 = frac( _TimeParameters.y );
				float RandomSwitch130 = step( ( temp_output_25_0 * 5.0 ) , 0.5 );
				float lerpResult32 = lerp( 0.85 , 1.0 , RandomSwitch130);
				float2 panner15 = ( mulTime17 * float2( 0,-0.5 ) + (temp_output_14_0*lerpResult32 + 0.0));
				float4 tex2DNode10 = tex2Dlod( _MaskMap, float4( panner15, 0, 0.0) );
				float lerpResult64 = lerp( 0.15 , 0.1 , RandomSwitch130);
				float mulTime19 = _TimeParameters.x * 0.5;
				float lerpResult35 = lerp( 0.75 , 1.0 , RandomSwitch130);
				float2 panner20 = ( mulTime19 * float2( 0,-0.5 ) + (temp_output_14_0*lerpResult35 + 0.0));
				float4 tex2DNode22 = tex2Dlod( _MaskMap, float4( panner20, 0, 0.0) );
				float RandomSwitch231 = step( temp_output_25_0 , 0.5 );
				float lerpResult70 = lerp( ( tex2DNode10.r * -lerpResult64 ) , ( lerpResult64 * tex2DNode22.r ) , RandomSwitch231);
				float SmallGlitches85 = lerpResult70;
				float temp_output_50_0 = step( v.vertex.xyz.y , ( _TimeParameters.y * 0.1 ) );
				float lerpResult58 = lerp( -0.075 , 0.075 , temp_output_50_0);
				float temp_output_55_0 = step( ( frac( _TimeParameters.y ) * 20.0 ) , 0.9 );
				float BigGlitches60 = ( lerpResult58 * temp_output_55_0 );
				float CombinedGlitches90 = ( SmallGlitches85 + BigGlitches60 );
				float2 uv_EmissiveRVertDispMaskG258 = v.ase_texcoord.xy;
				float4 _SpeedxStrenghtyFractUVz = float4(0.5,0.08,4,4);
				float mulTime245 = _TimeParameters.x * _SpeedxStrenghtyFractUVz.x;
				#ifdef _USESTEPTIME1_ON
				float staticSwitch247 = floor( mulTime245 );
				#else
				float staticSwitch247 = mulTime245;
				#endif
				float2 panner252 = ( staticSwitch247 * float2( -1,-1 ) + (FixedScreenUVs117).xy);
				float simplePerlin2D253 = snoise( panner252*5.0 );
				simplePerlin2D253 = simplePerlin2D253*0.5 + 0.5;
				float2 texCoord248 = v.ase_texcoord.xy * float2( 1,1 ) + float2( 0,0 );
				float pixelWidth249 =  1.0f / _SpeedxStrenghtyFractUVz.z;
				float pixelHeight249 = 1.0f / _SpeedxStrenghtyFractUVz.w;
				half2 pixelateduv249 = half2((int)(texCoord248.x / pixelWidth249) * pixelWidth249, (int)(texCoord248.y / pixelHeight249) * pixelHeight249);
				float2 panner250 = ( staticSwitch247 * float2( 1,1 ) + pixelateduv249);
				float simplePerlin2D251 = snoise( panner250*5.0 );
				simplePerlin2D251 = simplePerlin2D251*0.5 + 0.5;
				#ifdef _USEFRACTIONUUV1_ON
				float staticSwitch256 = simplePerlin2D251;
				#else
				float staticSwitch256 = simplePerlin2D253;
				#endif
				#ifdef _USEVERTEXDISPLACE1_ON
				float3 staticSwitch261 = ( v.ase_normal * ( tex2Dlod( _EmissiveRVertDispMaskG, float4( uv_EmissiveRVertDispMaskG258, 0, 0.0) ).g * staticSwitch256 * _SpeedxStrenghtyFractUVz.y ) );
				#else
				float3 staticSwitch261 = float3( 0,0,0 );
				#endif
				float3 VertNormalDisplace262 = staticSwitch261;
				float3 temp_output_310_0 = ( ( -normalizeResult177 * ( CombinedGlitches90 * _GlitchDisplacementStrenght ) ) + VertNormalDisplace262 );
				
				float3 normalizeResult323 = normalize( temp_output_310_0 );
				

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = temp_output_310_0;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif

				v.ase_normal = normalizeResult323;

				float3 positionWS = TransformObjectToWorld( v.vertex.xyz );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					o.worldPos = positionWS;
				#endif

				o.clipPos = TransformWorldToHClip( positionWS );
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					VertexPositionInputs vertexInput = (VertexPositionInputs)0;
					vertexInput.positionWS = positionWS;
					vertexInput.positionCS = o.clipPos;
					o.shadowCoord = GetShadowCoord( vertexInput );
				#endif

				return o;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 ase_normal : NORMAL;
				float4 ase_texcoord : TEXCOORD0;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.vertex;
				o.ase_normal = v.ase_normal;
				o.ase_texcoord = v.ase_texcoord;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
			   return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.ase_normal = patch[0].ase_normal * bary.x + patch[1].ase_normal * bary.y + patch[2].ase_normal * bary.z;
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.vertex.xyz - patch[i].ase_normal * (dot(o.vertex.xyz, patch[i].ase_normal) - dot(patch[i].vertex.xyz, patch[i].ase_normal));
				float phongStrength = _TessPhongStrength;
				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			half4 frag(VertexOutput IN  ) : SV_TARGET
			{
				UNITY_SETUP_INSTANCE_ID(IN);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( IN );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					float3 WorldPosition = IN.worldPos;
				#endif

				float4 ShadowCoords = float4( 0, 0, 0, 0 );

				#if defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
						ShadowCoords = IN.shadowCoord;
					#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
						ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
					#endif
				#endif

				

				float Alpha = 1;
				float AlphaClipThreshold = 0.5;

				#ifdef _ALPHATEST_ON
					clip(Alpha - AlphaClipThreshold);
				#endif

				#ifdef LOD_FADE_CROSSFADE
					LODDitheringTransition( IN.clipPos.xyz, unity_LODFade.x );
				#endif
				return 0;
			}
			ENDHLSL
		}

		
		Pass
		{
			
            Name "SceneSelectionPass"
            Tags { "LightMode"="SceneSelectionPass" }

			Cull Off

			HLSLPROGRAM

			#pragma multi_compile_instancing
			#define _SURFACE_TYPE_TRANSPARENT 1
			#define ASE_TESSELLATION 1
			#pragma require tessellation tessHW
			#pragma hull HullFunction
			#pragma domain DomainFunction
			#define ASE_FIXED_TESSELLATION
			#define ASE_SRP_VERSION -1


			#pragma vertex vert
			#pragma fragment frag

			#define ATTRIBUTES_NEED_NORMAL
			#define ATTRIBUTES_NEED_TANGENT
			#define SHADERPASS SHADERPASS_DEPTHONLY

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

			#define ASE_NEEDS_VERT_POSITION
			#define ASE_NEEDS_VERT_NORMAL
			#pragma shader_feature_local _USEVERTEXDISPLACE1_ON
			#pragma shader_feature_local _USEFRACTIONUUV1_ON
			#pragma shader_feature_local _USESTEPTIME1_ON


			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 ase_texcoord : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 clipPos : SV_POSITION;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _EmissiveColor;
			float4 _UVs1TilingxyScalezw;
			float4 _UVs2TilingxyScalezw;
			float4 _BaseColor;
			float2 _EmissiveTiling;
			float _StripesScale;
			float _StripesSpeed;
			float _GlitchedSpawSpeed;
			float _MinPulseOpacity;
			float _PulseSpeed;
			float _FresnelScale;
			float _GlitchesTiling;
			float _RefractionOffset;
			float _DistortionBlend;
			float _Panner2;
			float _Panner1;
			float _GlitchDisplacementStrenght;
			float _OverallOpacity;
			float _StripesIntensity;
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			sampler2D _MaskMap;
			sampler2D _EmissiveRVertDispMaskG;


			float3 mod2D289( float3 x ) { return x - floor( x * ( 1.0 / 289.0 ) ) * 289.0; }
			float2 mod2D289( float2 x ) { return x - floor( x * ( 1.0 / 289.0 ) ) * 289.0; }
			float3 permute( float3 x ) { return mod2D289( ( ( x * 34.0 ) + 1.0 ) * x ); }
			float snoise( float2 v )
			{
				const float4 C = float4( 0.211324865405187, 0.366025403784439, -0.577350269189626, 0.024390243902439 );
				float2 i = floor( v + dot( v, C.yy ) );
				float2 x0 = v - i + dot( i, C.xx );
				float2 i1;
				i1 = ( x0.x > x0.y ) ? float2( 1.0, 0.0 ) : float2( 0.0, 1.0 );
				float4 x12 = x0.xyxy + C.xxzz;
				x12.xy -= i1;
				i = mod2D289( i );
				float3 p = permute( permute( i.y + float3( 0.0, i1.y, 1.0 ) ) + i.x + float3( 0.0, i1.x, 1.0 ) );
				float3 m = max( 0.5 - float3( dot( x0, x0 ), dot( x12.xy, x12.xy ), dot( x12.zw, x12.zw ) ), 0.0 );
				m = m * m;
				m = m * m;
				float3 x = 2.0 * frac( p * C.www ) - 1.0;
				float3 h = abs( x ) - 0.5;
				float3 ox = floor( x + 0.5 );
				float3 a0 = x - ox;
				m *= 1.79284291400159 - 0.85373472095314 * ( a0 * a0 + h * h );
				float3 g;
				g.x = a0.x * x0.x + h.x * x0.y;
				g.yz = a0.yz * x12.xz + h.yz * x12.yw;
				return 130.0 * dot( m, g );
			}
			

			int _ObjectId;
			int _PassValue;

			struct SurfaceDescription
			{
				float Alpha;
				float AlphaClipThreshold;
			};

			VertexOutput VertexFunction(VertexInput v  )
			{
				VertexOutput o;
				ZERO_INITIALIZE(VertexOutput, o);

				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float3 ase_worldPos = TransformObjectToWorld( (v.vertex).xyz );
				float3 ase_worldViewDir = ( _WorldSpaceCameraPos.xyz - ase_worldPos );
				ase_worldViewDir = SafeNormalize( ase_worldViewDir );
				float3 normalizeResult177 = normalize( cross( ase_worldViewDir , float3( 0,1,0 ) ) );
				float mulTime17 = _TimeParameters.x * 0.25;
				float4 unityObjectToClipPos96 = TransformWorldToHClip(TransformObjectToWorld(v.vertex.xyz));
				float4 computeScreenPos97 = ComputeScreenPos( unityObjectToClipPos96 );
				computeScreenPos97 = computeScreenPos97 / computeScreenPos97.w;
				computeScreenPos97.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? computeScreenPos97.z : computeScreenPos97.z* 0.5 + 0.5;
				float4 unityObjectToClipPos102 = TransformWorldToHClip(TransformObjectToWorld(float3(0,0,0)));
				float4 computeScreenPos103 = ComputeScreenPos( unityObjectToClipPos102 );
				computeScreenPos103 = computeScreenPos103 / computeScreenPos103.w;
				computeScreenPos103.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? computeScreenPos103.z : computeScreenPos103.z* 0.5 + 0.5;
				float4 transform109 = mul(GetObjectToWorldMatrix(),float4( 0,0,0,1 ));
				float4 break112 = ( ( ( computeScreenPos97 * _GlitchesTiling ) - ( _GlitchesTiling * computeScreenPos103 ) ) * distance( ( float4( _WorldSpaceCameraPos , 0.0 ) - transform109 ) , float4( 0,0,0,0 ) ) );
				float4 appendResult113 = (float4(( break112.x * ( _ScreenParams.x / _ScreenParams.y ) ) , break112.y , break112.z , break112.w));
				float4 FixedScreenUVs117 = appendResult113;
				float2 temp_output_14_0 = (FixedScreenUVs117).xy;
				float temp_output_25_0 = frac( _TimeParameters.y );
				float RandomSwitch130 = step( ( temp_output_25_0 * 5.0 ) , 0.5 );
				float lerpResult32 = lerp( 0.85 , 1.0 , RandomSwitch130);
				float2 panner15 = ( mulTime17 * float2( 0,-0.5 ) + (temp_output_14_0*lerpResult32 + 0.0));
				float4 tex2DNode10 = tex2Dlod( _MaskMap, float4( panner15, 0, 0.0) );
				float lerpResult64 = lerp( 0.15 , 0.1 , RandomSwitch130);
				float mulTime19 = _TimeParameters.x * 0.5;
				float lerpResult35 = lerp( 0.75 , 1.0 , RandomSwitch130);
				float2 panner20 = ( mulTime19 * float2( 0,-0.5 ) + (temp_output_14_0*lerpResult35 + 0.0));
				float4 tex2DNode22 = tex2Dlod( _MaskMap, float4( panner20, 0, 0.0) );
				float RandomSwitch231 = step( temp_output_25_0 , 0.5 );
				float lerpResult70 = lerp( ( tex2DNode10.r * -lerpResult64 ) , ( lerpResult64 * tex2DNode22.r ) , RandomSwitch231);
				float SmallGlitches85 = lerpResult70;
				float temp_output_50_0 = step( v.vertex.xyz.y , ( _TimeParameters.y * 0.1 ) );
				float lerpResult58 = lerp( -0.075 , 0.075 , temp_output_50_0);
				float temp_output_55_0 = step( ( frac( _TimeParameters.y ) * 20.0 ) , 0.9 );
				float BigGlitches60 = ( lerpResult58 * temp_output_55_0 );
				float CombinedGlitches90 = ( SmallGlitches85 + BigGlitches60 );
				float2 uv_EmissiveRVertDispMaskG258 = v.ase_texcoord.xy;
				float4 _SpeedxStrenghtyFractUVz = float4(0.5,0.08,4,4);
				float mulTime245 = _TimeParameters.x * _SpeedxStrenghtyFractUVz.x;
				#ifdef _USESTEPTIME1_ON
				float staticSwitch247 = floor( mulTime245 );
				#else
				float staticSwitch247 = mulTime245;
				#endif
				float2 panner252 = ( staticSwitch247 * float2( -1,-1 ) + (FixedScreenUVs117).xy);
				float simplePerlin2D253 = snoise( panner252*5.0 );
				simplePerlin2D253 = simplePerlin2D253*0.5 + 0.5;
				float2 texCoord248 = v.ase_texcoord.xy * float2( 1,1 ) + float2( 0,0 );
				float pixelWidth249 =  1.0f / _SpeedxStrenghtyFractUVz.z;
				float pixelHeight249 = 1.0f / _SpeedxStrenghtyFractUVz.w;
				half2 pixelateduv249 = half2((int)(texCoord248.x / pixelWidth249) * pixelWidth249, (int)(texCoord248.y / pixelHeight249) * pixelHeight249);
				float2 panner250 = ( staticSwitch247 * float2( 1,1 ) + pixelateduv249);
				float simplePerlin2D251 = snoise( panner250*5.0 );
				simplePerlin2D251 = simplePerlin2D251*0.5 + 0.5;
				#ifdef _USEFRACTIONUUV1_ON
				float staticSwitch256 = simplePerlin2D251;
				#else
				float staticSwitch256 = simplePerlin2D253;
				#endif
				#ifdef _USEVERTEXDISPLACE1_ON
				float3 staticSwitch261 = ( v.ase_normal * ( tex2Dlod( _EmissiveRVertDispMaskG, float4( uv_EmissiveRVertDispMaskG258, 0, 0.0) ).g * staticSwitch256 * _SpeedxStrenghtyFractUVz.y ) );
				#else
				float3 staticSwitch261 = float3( 0,0,0 );
				#endif
				float3 VertNormalDisplace262 = staticSwitch261;
				float3 temp_output_310_0 = ( ( -normalizeResult177 * ( CombinedGlitches90 * _GlitchDisplacementStrenght ) ) + VertNormalDisplace262 );
				
				float3 normalizeResult323 = normalize( temp_output_310_0 );
				

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = temp_output_310_0;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif

				v.ase_normal = normalizeResult323;

				float3 positionWS = TransformObjectToWorld( v.vertex.xyz );
				o.clipPos = TransformWorldToHClip(positionWS);

				return o;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 ase_normal : NORMAL;
				float4 ase_texcoord : TEXCOORD0;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.vertex;
				o.ase_normal = v.ase_normal;
				o.ase_texcoord = v.ase_texcoord;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
				return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.ase_normal = patch[0].ase_normal * bary.x + patch[1].ase_normal * bary.y + patch[2].ase_normal * bary.z;
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.vertex.xyz - patch[i].ase_normal * (dot(o.vertex.xyz, patch[i].ase_normal) - dot(patch[i].vertex.xyz, patch[i].ase_normal));
				float phongStrength = _TessPhongStrength;
				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			half4 frag(VertexOutput IN ) : SV_TARGET
			{
				SurfaceDescription surfaceDescription = (SurfaceDescription)0;

				

				surfaceDescription.Alpha = 1;
				surfaceDescription.AlphaClipThreshold = 0.5;

				#if _ALPHATEST_ON
					float alphaClipThreshold = 0.01f;
					#if ALPHA_CLIP_THRESHOLD
						alphaClipThreshold = surfaceDescription.AlphaClipThreshold;
					#endif
					clip(surfaceDescription.Alpha - alphaClipThreshold);
				#endif

				half4 outColor = half4(_ObjectId, _PassValue, 1.0, 1.0);
				return outColor;
			}
			ENDHLSL
		}

		
		Pass
		{
			
            Name "ScenePickingPass"
            Tags { "LightMode"="Picking" }

			HLSLPROGRAM

			#pragma multi_compile_instancing
			#define _SURFACE_TYPE_TRANSPARENT 1
			#define ASE_TESSELLATION 1
			#pragma require tessellation tessHW
			#pragma hull HullFunction
			#pragma domain DomainFunction
			#define ASE_FIXED_TESSELLATION
			#define ASE_SRP_VERSION -1


			#pragma vertex vert
			#pragma fragment frag

			#define ATTRIBUTES_NEED_NORMAL
			#define ATTRIBUTES_NEED_TANGENT
			#define SHADERPASS SHADERPASS_DEPTHONLY

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

			#define ASE_NEEDS_VERT_POSITION
			#define ASE_NEEDS_VERT_NORMAL
			#pragma shader_feature_local _USEVERTEXDISPLACE1_ON
			#pragma shader_feature_local _USEFRACTIONUUV1_ON
			#pragma shader_feature_local _USESTEPTIME1_ON


			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 ase_texcoord : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 clipPos : SV_POSITION;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _EmissiveColor;
			float4 _UVs1TilingxyScalezw;
			float4 _UVs2TilingxyScalezw;
			float4 _BaseColor;
			float2 _EmissiveTiling;
			float _StripesScale;
			float _StripesSpeed;
			float _GlitchedSpawSpeed;
			float _MinPulseOpacity;
			float _PulseSpeed;
			float _FresnelScale;
			float _GlitchesTiling;
			float _RefractionOffset;
			float _DistortionBlend;
			float _Panner2;
			float _Panner1;
			float _GlitchDisplacementStrenght;
			float _OverallOpacity;
			float _StripesIntensity;
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			sampler2D _MaskMap;
			sampler2D _EmissiveRVertDispMaskG;


			float3 mod2D289( float3 x ) { return x - floor( x * ( 1.0 / 289.0 ) ) * 289.0; }
			float2 mod2D289( float2 x ) { return x - floor( x * ( 1.0 / 289.0 ) ) * 289.0; }
			float3 permute( float3 x ) { return mod2D289( ( ( x * 34.0 ) + 1.0 ) * x ); }
			float snoise( float2 v )
			{
				const float4 C = float4( 0.211324865405187, 0.366025403784439, -0.577350269189626, 0.024390243902439 );
				float2 i = floor( v + dot( v, C.yy ) );
				float2 x0 = v - i + dot( i, C.xx );
				float2 i1;
				i1 = ( x0.x > x0.y ) ? float2( 1.0, 0.0 ) : float2( 0.0, 1.0 );
				float4 x12 = x0.xyxy + C.xxzz;
				x12.xy -= i1;
				i = mod2D289( i );
				float3 p = permute( permute( i.y + float3( 0.0, i1.y, 1.0 ) ) + i.x + float3( 0.0, i1.x, 1.0 ) );
				float3 m = max( 0.5 - float3( dot( x0, x0 ), dot( x12.xy, x12.xy ), dot( x12.zw, x12.zw ) ), 0.0 );
				m = m * m;
				m = m * m;
				float3 x = 2.0 * frac( p * C.www ) - 1.0;
				float3 h = abs( x ) - 0.5;
				float3 ox = floor( x + 0.5 );
				float3 a0 = x - ox;
				m *= 1.79284291400159 - 0.85373472095314 * ( a0 * a0 + h * h );
				float3 g;
				g.x = a0.x * x0.x + h.x * x0.y;
				g.yz = a0.yz * x12.xz + h.yz * x12.yw;
				return 130.0 * dot( m, g );
			}
			

			float4 _SelectionID;


			struct SurfaceDescription
			{
				float Alpha;
				float AlphaClipThreshold;
			};

			VertexOutput VertexFunction(VertexInput v  )
			{
				VertexOutput o;
				ZERO_INITIALIZE(VertexOutput, o);

				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float3 ase_worldPos = TransformObjectToWorld( (v.vertex).xyz );
				float3 ase_worldViewDir = ( _WorldSpaceCameraPos.xyz - ase_worldPos );
				ase_worldViewDir = SafeNormalize( ase_worldViewDir );
				float3 normalizeResult177 = normalize( cross( ase_worldViewDir , float3( 0,1,0 ) ) );
				float mulTime17 = _TimeParameters.x * 0.25;
				float4 unityObjectToClipPos96 = TransformWorldToHClip(TransformObjectToWorld(v.vertex.xyz));
				float4 computeScreenPos97 = ComputeScreenPos( unityObjectToClipPos96 );
				computeScreenPos97 = computeScreenPos97 / computeScreenPos97.w;
				computeScreenPos97.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? computeScreenPos97.z : computeScreenPos97.z* 0.5 + 0.5;
				float4 unityObjectToClipPos102 = TransformWorldToHClip(TransformObjectToWorld(float3(0,0,0)));
				float4 computeScreenPos103 = ComputeScreenPos( unityObjectToClipPos102 );
				computeScreenPos103 = computeScreenPos103 / computeScreenPos103.w;
				computeScreenPos103.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? computeScreenPos103.z : computeScreenPos103.z* 0.5 + 0.5;
				float4 transform109 = mul(GetObjectToWorldMatrix(),float4( 0,0,0,1 ));
				float4 break112 = ( ( ( computeScreenPos97 * _GlitchesTiling ) - ( _GlitchesTiling * computeScreenPos103 ) ) * distance( ( float4( _WorldSpaceCameraPos , 0.0 ) - transform109 ) , float4( 0,0,0,0 ) ) );
				float4 appendResult113 = (float4(( break112.x * ( _ScreenParams.x / _ScreenParams.y ) ) , break112.y , break112.z , break112.w));
				float4 FixedScreenUVs117 = appendResult113;
				float2 temp_output_14_0 = (FixedScreenUVs117).xy;
				float temp_output_25_0 = frac( _TimeParameters.y );
				float RandomSwitch130 = step( ( temp_output_25_0 * 5.0 ) , 0.5 );
				float lerpResult32 = lerp( 0.85 , 1.0 , RandomSwitch130);
				float2 panner15 = ( mulTime17 * float2( 0,-0.5 ) + (temp_output_14_0*lerpResult32 + 0.0));
				float4 tex2DNode10 = tex2Dlod( _MaskMap, float4( panner15, 0, 0.0) );
				float lerpResult64 = lerp( 0.15 , 0.1 , RandomSwitch130);
				float mulTime19 = _TimeParameters.x * 0.5;
				float lerpResult35 = lerp( 0.75 , 1.0 , RandomSwitch130);
				float2 panner20 = ( mulTime19 * float2( 0,-0.5 ) + (temp_output_14_0*lerpResult35 + 0.0));
				float4 tex2DNode22 = tex2Dlod( _MaskMap, float4( panner20, 0, 0.0) );
				float RandomSwitch231 = step( temp_output_25_0 , 0.5 );
				float lerpResult70 = lerp( ( tex2DNode10.r * -lerpResult64 ) , ( lerpResult64 * tex2DNode22.r ) , RandomSwitch231);
				float SmallGlitches85 = lerpResult70;
				float temp_output_50_0 = step( v.vertex.xyz.y , ( _TimeParameters.y * 0.1 ) );
				float lerpResult58 = lerp( -0.075 , 0.075 , temp_output_50_0);
				float temp_output_55_0 = step( ( frac( _TimeParameters.y ) * 20.0 ) , 0.9 );
				float BigGlitches60 = ( lerpResult58 * temp_output_55_0 );
				float CombinedGlitches90 = ( SmallGlitches85 + BigGlitches60 );
				float2 uv_EmissiveRVertDispMaskG258 = v.ase_texcoord.xy;
				float4 _SpeedxStrenghtyFractUVz = float4(0.5,0.08,4,4);
				float mulTime245 = _TimeParameters.x * _SpeedxStrenghtyFractUVz.x;
				#ifdef _USESTEPTIME1_ON
				float staticSwitch247 = floor( mulTime245 );
				#else
				float staticSwitch247 = mulTime245;
				#endif
				float2 panner252 = ( staticSwitch247 * float2( -1,-1 ) + (FixedScreenUVs117).xy);
				float simplePerlin2D253 = snoise( panner252*5.0 );
				simplePerlin2D253 = simplePerlin2D253*0.5 + 0.5;
				float2 texCoord248 = v.ase_texcoord.xy * float2( 1,1 ) + float2( 0,0 );
				float pixelWidth249 =  1.0f / _SpeedxStrenghtyFractUVz.z;
				float pixelHeight249 = 1.0f / _SpeedxStrenghtyFractUVz.w;
				half2 pixelateduv249 = half2((int)(texCoord248.x / pixelWidth249) * pixelWidth249, (int)(texCoord248.y / pixelHeight249) * pixelHeight249);
				float2 panner250 = ( staticSwitch247 * float2( 1,1 ) + pixelateduv249);
				float simplePerlin2D251 = snoise( panner250*5.0 );
				simplePerlin2D251 = simplePerlin2D251*0.5 + 0.5;
				#ifdef _USEFRACTIONUUV1_ON
				float staticSwitch256 = simplePerlin2D251;
				#else
				float staticSwitch256 = simplePerlin2D253;
				#endif
				#ifdef _USEVERTEXDISPLACE1_ON
				float3 staticSwitch261 = ( v.ase_normal * ( tex2Dlod( _EmissiveRVertDispMaskG, float4( uv_EmissiveRVertDispMaskG258, 0, 0.0) ).g * staticSwitch256 * _SpeedxStrenghtyFractUVz.y ) );
				#else
				float3 staticSwitch261 = float3( 0,0,0 );
				#endif
				float3 VertNormalDisplace262 = staticSwitch261;
				float3 temp_output_310_0 = ( ( -normalizeResult177 * ( CombinedGlitches90 * _GlitchDisplacementStrenght ) ) + VertNormalDisplace262 );
				
				float3 normalizeResult323 = normalize( temp_output_310_0 );
				
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif
				float3 vertexValue = temp_output_310_0;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif
				v.ase_normal = normalizeResult323;

				float3 positionWS = TransformObjectToWorld( v.vertex.xyz );
				o.clipPos = TransformWorldToHClip(positionWS);
				return o;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 ase_normal : NORMAL;
				float4 ase_texcoord : TEXCOORD0;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.vertex;
				o.ase_normal = v.ase_normal;
				o.ase_texcoord = v.ase_texcoord;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
				return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.ase_normal = patch[0].ase_normal * bary.x + patch[1].ase_normal * bary.y + patch[2].ase_normal * bary.z;
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.vertex.xyz - patch[i].ase_normal * (dot(o.vertex.xyz, patch[i].ase_normal) - dot(patch[i].vertex.xyz, patch[i].ase_normal));
				float phongStrength = _TessPhongStrength;
				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			half4 frag(VertexOutput IN ) : SV_TARGET
			{
				SurfaceDescription surfaceDescription = (SurfaceDescription)0;

				

				surfaceDescription.Alpha = 1;
				surfaceDescription.AlphaClipThreshold = 0.5;

				#if _ALPHATEST_ON
					float alphaClipThreshold = 0.01f;
					#if ALPHA_CLIP_THRESHOLD
						alphaClipThreshold = surfaceDescription.AlphaClipThreshold;
					#endif
					clip(surfaceDescription.Alpha - alphaClipThreshold);
				#endif

				half4 outColor = 0;
				outColor = _SelectionID;

				return outColor;
			}

			ENDHLSL
		}

		
		Pass
		{
			
            Name "DepthNormals"
            Tags { "LightMode"="DepthNormalsOnly" }

			ZTest LEqual
			ZWrite On


			HLSLPROGRAM

			#pragma multi_compile_instancing
			#define _SURFACE_TYPE_TRANSPARENT 1
			#define ASE_TESSELLATION 1
			#pragma require tessellation tessHW
			#pragma hull HullFunction
			#pragma domain DomainFunction
			#define ASE_FIXED_TESSELLATION
			#define ASE_SRP_VERSION -1


			#pragma vertex vert
			#pragma fragment frag

			#pragma multi_compile_fragment _ _WRITE_RENDERING_LAYERS
        	#pragma multi_compile_fragment _ _GBUFFER_NORMALS_OCT

			#define ATTRIBUTES_NEED_NORMAL
			#define ATTRIBUTES_NEED_TANGENT
			#define VARYINGS_NEED_NORMAL_WS

			#define SHADERPASS SHADERPASS_DEPTHNORMALSONLY

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

			#define ASE_NEEDS_VERT_POSITION
			#define ASE_NEEDS_VERT_NORMAL
			#pragma shader_feature_local _USEVERTEXDISPLACE1_ON
			#pragma shader_feature_local _USEFRACTIONUUV1_ON
			#pragma shader_feature_local _USESTEPTIME1_ON


			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 ase_texcoord : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 clipPos : SV_POSITION;
				float3 normalWS : TEXCOORD0;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _EmissiveColor;
			float4 _UVs1TilingxyScalezw;
			float4 _UVs2TilingxyScalezw;
			float4 _BaseColor;
			float2 _EmissiveTiling;
			float _StripesScale;
			float _StripesSpeed;
			float _GlitchedSpawSpeed;
			float _MinPulseOpacity;
			float _PulseSpeed;
			float _FresnelScale;
			float _GlitchesTiling;
			float _RefractionOffset;
			float _DistortionBlend;
			float _Panner2;
			float _Panner1;
			float _GlitchDisplacementStrenght;
			float _OverallOpacity;
			float _StripesIntensity;
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			sampler2D _MaskMap;
			sampler2D _EmissiveRVertDispMaskG;


			float3 mod2D289( float3 x ) { return x - floor( x * ( 1.0 / 289.0 ) ) * 289.0; }
			float2 mod2D289( float2 x ) { return x - floor( x * ( 1.0 / 289.0 ) ) * 289.0; }
			float3 permute( float3 x ) { return mod2D289( ( ( x * 34.0 ) + 1.0 ) * x ); }
			float snoise( float2 v )
			{
				const float4 C = float4( 0.211324865405187, 0.366025403784439, -0.577350269189626, 0.024390243902439 );
				float2 i = floor( v + dot( v, C.yy ) );
				float2 x0 = v - i + dot( i, C.xx );
				float2 i1;
				i1 = ( x0.x > x0.y ) ? float2( 1.0, 0.0 ) : float2( 0.0, 1.0 );
				float4 x12 = x0.xyxy + C.xxzz;
				x12.xy -= i1;
				i = mod2D289( i );
				float3 p = permute( permute( i.y + float3( 0.0, i1.y, 1.0 ) ) + i.x + float3( 0.0, i1.x, 1.0 ) );
				float3 m = max( 0.5 - float3( dot( x0, x0 ), dot( x12.xy, x12.xy ), dot( x12.zw, x12.zw ) ), 0.0 );
				m = m * m;
				m = m * m;
				float3 x = 2.0 * frac( p * C.www ) - 1.0;
				float3 h = abs( x ) - 0.5;
				float3 ox = floor( x + 0.5 );
				float3 a0 = x - ox;
				m *= 1.79284291400159 - 0.85373472095314 * ( a0 * a0 + h * h );
				float3 g;
				g.x = a0.x * x0.x + h.x * x0.y;
				g.yz = a0.yz * x12.xz + h.yz * x12.yw;
				return 130.0 * dot( m, g );
			}
			

			struct SurfaceDescription
			{
				float Alpha;
				float AlphaClipThreshold;
			};

			VertexOutput VertexFunction(VertexInput v  )
			{
				VertexOutput o;
				ZERO_INITIALIZE(VertexOutput, o);

				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float3 ase_worldPos = TransformObjectToWorld( (v.vertex).xyz );
				float3 ase_worldViewDir = ( _WorldSpaceCameraPos.xyz - ase_worldPos );
				ase_worldViewDir = SafeNormalize( ase_worldViewDir );
				float3 normalizeResult177 = normalize( cross( ase_worldViewDir , float3( 0,1,0 ) ) );
				float mulTime17 = _TimeParameters.x * 0.25;
				float4 unityObjectToClipPos96 = TransformWorldToHClip(TransformObjectToWorld(v.vertex.xyz));
				float4 computeScreenPos97 = ComputeScreenPos( unityObjectToClipPos96 );
				computeScreenPos97 = computeScreenPos97 / computeScreenPos97.w;
				computeScreenPos97.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? computeScreenPos97.z : computeScreenPos97.z* 0.5 + 0.5;
				float4 unityObjectToClipPos102 = TransformWorldToHClip(TransformObjectToWorld(float3(0,0,0)));
				float4 computeScreenPos103 = ComputeScreenPos( unityObjectToClipPos102 );
				computeScreenPos103 = computeScreenPos103 / computeScreenPos103.w;
				computeScreenPos103.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? computeScreenPos103.z : computeScreenPos103.z* 0.5 + 0.5;
				float4 transform109 = mul(GetObjectToWorldMatrix(),float4( 0,0,0,1 ));
				float4 break112 = ( ( ( computeScreenPos97 * _GlitchesTiling ) - ( _GlitchesTiling * computeScreenPos103 ) ) * distance( ( float4( _WorldSpaceCameraPos , 0.0 ) - transform109 ) , float4( 0,0,0,0 ) ) );
				float4 appendResult113 = (float4(( break112.x * ( _ScreenParams.x / _ScreenParams.y ) ) , break112.y , break112.z , break112.w));
				float4 FixedScreenUVs117 = appendResult113;
				float2 temp_output_14_0 = (FixedScreenUVs117).xy;
				float temp_output_25_0 = frac( _TimeParameters.y );
				float RandomSwitch130 = step( ( temp_output_25_0 * 5.0 ) , 0.5 );
				float lerpResult32 = lerp( 0.85 , 1.0 , RandomSwitch130);
				float2 panner15 = ( mulTime17 * float2( 0,-0.5 ) + (temp_output_14_0*lerpResult32 + 0.0));
				float4 tex2DNode10 = tex2Dlod( _MaskMap, float4( panner15, 0, 0.0) );
				float lerpResult64 = lerp( 0.15 , 0.1 , RandomSwitch130);
				float mulTime19 = _TimeParameters.x * 0.5;
				float lerpResult35 = lerp( 0.75 , 1.0 , RandomSwitch130);
				float2 panner20 = ( mulTime19 * float2( 0,-0.5 ) + (temp_output_14_0*lerpResult35 + 0.0));
				float4 tex2DNode22 = tex2Dlod( _MaskMap, float4( panner20, 0, 0.0) );
				float RandomSwitch231 = step( temp_output_25_0 , 0.5 );
				float lerpResult70 = lerp( ( tex2DNode10.r * -lerpResult64 ) , ( lerpResult64 * tex2DNode22.r ) , RandomSwitch231);
				float SmallGlitches85 = lerpResult70;
				float temp_output_50_0 = step( v.vertex.xyz.y , ( _TimeParameters.y * 0.1 ) );
				float lerpResult58 = lerp( -0.075 , 0.075 , temp_output_50_0);
				float temp_output_55_0 = step( ( frac( _TimeParameters.y ) * 20.0 ) , 0.9 );
				float BigGlitches60 = ( lerpResult58 * temp_output_55_0 );
				float CombinedGlitches90 = ( SmallGlitches85 + BigGlitches60 );
				float2 uv_EmissiveRVertDispMaskG258 = v.ase_texcoord.xy;
				float4 _SpeedxStrenghtyFractUVz = float4(0.5,0.08,4,4);
				float mulTime245 = _TimeParameters.x * _SpeedxStrenghtyFractUVz.x;
				#ifdef _USESTEPTIME1_ON
				float staticSwitch247 = floor( mulTime245 );
				#else
				float staticSwitch247 = mulTime245;
				#endif
				float2 panner252 = ( staticSwitch247 * float2( -1,-1 ) + (FixedScreenUVs117).xy);
				float simplePerlin2D253 = snoise( panner252*5.0 );
				simplePerlin2D253 = simplePerlin2D253*0.5 + 0.5;
				float2 texCoord248 = v.ase_texcoord.xy * float2( 1,1 ) + float2( 0,0 );
				float pixelWidth249 =  1.0f / _SpeedxStrenghtyFractUVz.z;
				float pixelHeight249 = 1.0f / _SpeedxStrenghtyFractUVz.w;
				half2 pixelateduv249 = half2((int)(texCoord248.x / pixelWidth249) * pixelWidth249, (int)(texCoord248.y / pixelHeight249) * pixelHeight249);
				float2 panner250 = ( staticSwitch247 * float2( 1,1 ) + pixelateduv249);
				float simplePerlin2D251 = snoise( panner250*5.0 );
				simplePerlin2D251 = simplePerlin2D251*0.5 + 0.5;
				#ifdef _USEFRACTIONUUV1_ON
				float staticSwitch256 = simplePerlin2D251;
				#else
				float staticSwitch256 = simplePerlin2D253;
				#endif
				#ifdef _USEVERTEXDISPLACE1_ON
				float3 staticSwitch261 = ( v.ase_normal * ( tex2Dlod( _EmissiveRVertDispMaskG, float4( uv_EmissiveRVertDispMaskG258, 0, 0.0) ).g * staticSwitch256 * _SpeedxStrenghtyFractUVz.y ) );
				#else
				float3 staticSwitch261 = float3( 0,0,0 );
				#endif
				float3 VertNormalDisplace262 = staticSwitch261;
				float3 temp_output_310_0 = ( ( -normalizeResult177 * ( CombinedGlitches90 * _GlitchDisplacementStrenght ) ) + VertNormalDisplace262 );
				
				float3 normalizeResult323 = normalize( temp_output_310_0 );
				
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = temp_output_310_0;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif

				v.ase_normal = normalizeResult323;

				float3 positionWS = TransformObjectToWorld( v.vertex.xyz );
				float3 normalWS = TransformObjectToWorldNormal(v.ase_normal);

				o.clipPos = TransformWorldToHClip(positionWS);
				o.normalWS.xyz =  normalWS;

				return o;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 ase_normal : NORMAL;
				float4 ase_texcoord : TEXCOORD0;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.vertex;
				o.ase_normal = v.ase_normal;
				o.ase_texcoord = v.ase_texcoord;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
				return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.ase_normal = patch[0].ase_normal * bary.x + patch[1].ase_normal * bary.y + patch[2].ase_normal * bary.z;
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.vertex.xyz - patch[i].ase_normal * (dot(o.vertex.xyz, patch[i].ase_normal) - dot(patch[i].vertex.xyz, patch[i].ase_normal));
				float phongStrength = _TessPhongStrength;
				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			void frag( VertexOutput IN
				, out half4 outNormalWS : SV_Target0
			#ifdef _WRITE_RENDERING_LAYERS
				, out float4 outRenderingLayers : SV_Target1
			#endif
				 )
			{
				SurfaceDescription surfaceDescription = (SurfaceDescription)0;

				

				surfaceDescription.Alpha = 1;
				surfaceDescription.AlphaClipThreshold = 0.5;

				#if _ALPHATEST_ON
					clip(surfaceDescription.Alpha - surfaceDescription.AlphaClipThreshold);
				#endif

				#ifdef LOD_FADE_CROSSFADE
					LODDitheringTransition( IN.clipPos.xyz, unity_LODFade.x );
				#endif

				#if defined(_GBUFFER_NORMALS_OCT)
					float3 normalWS = normalize(IN.normalWS);
					float2 octNormalWS = PackNormalOctQuadEncode(normalWS);           // values between [-1, +1], must use fp32 on some platforms
					float2 remappedOctNormalWS = saturate(octNormalWS * 0.5 + 0.5);   // values between [ 0,  1]
					half3 packedNormalWS = PackFloat2To888(remappedOctNormalWS);      // values between [ 0,  1]
					outNormalWS = half4(packedNormalWS, 0.0);
				#else
					float3 normalWS = IN.normalWS;
					outNormalWS = half4(NormalizeNormalPerPixel(normalWS), 0.0);
				#endif

				#ifdef _WRITE_RENDERING_LAYERS
					uint renderingLayers = GetMeshRenderingLayer();
					outRenderingLayers = float4(EncodeMeshRenderingLayer(renderingLayers), 0, 0, 0);
				#endif
			}

			ENDHLSL
		}

	
	}
	
	CustomEditor "UnityEditor.ShaderGraphUnlitGUI"
	FallBack "Hidden/Shader Graph/FallbackError"
	
	Fallback Off
}
/*ASEBEGIN
Version=19102
Node;AmplifyShaderEditor.CommentaryNode;277;-6805.567,-2398.185;Inherit;False;1105.588;429.2466;Fresnel;6;271;272;273;274;275;276;;0.3349057,1,0.6892094,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;263;-2888.704,3508.655;Inherit;False;2916.117;751.1599;Vertex Normal Displace;19;244;245;246;249;248;250;254;255;252;253;251;247;257;258;259;260;256;261;262;;0.465559,0,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;237;-4963.531,-4301.94;Inherit;False;2592.08;1763.71;Stripes and Pulse;7;224;219;218;214;215;235;236;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;236;-4613.824,-4251.94;Inherit;False;2194.155;750.0444;Stripes;12;270;234;228;227;225;226;229;216;220;217;212;267;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;235;-4672.378,-3109.76;Inherit;False;2242.405;521.6438;Pulse;13;233;268;269;264;266;265;232;231;230;213;223;222;221;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;206;-5983.486,-1868.27;Inherit;False;3015.258;1118.414;Emission Color;33;183;184;185;187;186;189;190;196;195;197;192;194;193;198;199;204;191;203;205;209;208;207;242;243;241;240;239;278;279;280;281;282;283;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;209;-3787.858,-1305.998;Inherit;False;232.6101;206.48;B;1;202;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;208;-3780.28,-1562.051;Inherit;False;232.6101;206.48;G;1;201;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;207;-3786.917,-1794.203;Inherit;False;232.6101;206.48;R;1;200;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;164;-5289.573,2034.639;Inherit;False;1253.428;517.45;Screen UV;8;155;156;157;159;154;158;162;163;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;153;-5138.134,1248.637;Inherit;False;1246.06;636.2664;Distortion;7;148;149;150;151;152;160;161;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;145;-3681.406,403.9091;Inherit;False;1430.8;1149.219;UVs;21;120;121;127;122;124;128;125;126;129;136;135;132;134;138;137;141;139;140;142;143;144;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;118;-6647.684,193.8987;Inherit;False;2542.373;928.2654;Fixed Screen Pos;21;95;98;96;97;100;101;102;103;104;105;106;107;109;108;111;112;115;116;114;113;117;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;91;-452.0713,1908.67;Inherit;False;701.4;245.1599;Combined Glitches;4;87;88;89;90;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;86;-1964.631,-296.1724;Inherit;False;1407.2;634.16;SmallGlitches;8;62;64;65;66;67;70;63;85;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;84;-2039.396,366;Inherit;False;913.4;302.48;Small Glitches Mask;5;79;82;81;80;83;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;75;-2096.648,1891.351;Inherit;False;1273.288;667.2792;Big Glitches;13;49;50;51;52;53;54;55;56;57;58;59;60;61;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;74;-1225.011,1133.689;Inherit;False;1291.982;520.16;Small Glitches Spawn Speed;13;43;41;40;36;37;38;39;44;45;42;46;47;48;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;72;-2155.242,1079.099;Inherit;False;785;386;Randoms Switches;7;24;30;31;27;25;28;29;;1,1,1,1;0;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;29;-1895.174,1185.151;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;5;False;1;FLOAT;0
Node;AmplifyShaderEditor.StepOpNode;28;-1747.174,1182.151;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0.5;False;1;FLOAT;0
Node;AmplifyShaderEditor.FractNode;25;-1878.174,1356.151;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.StepOpNode;27;-1739.174,1356.151;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0.5;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;31;-1613.174,1357.151;Inherit;False;RandomSwitch2;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;30;-1613.174,1189.151;Inherit;False;RandomSwitch1;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SinTimeNode;24;-2067.106,1242.703;Inherit;False;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ComponentMaskNode;14;-3105.499,-257.7763;Inherit;False;True;True;False;False;1;0;FLOAT4;0,0,0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;16;-2869.499,-250.7763;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT;1;False;2;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleTimeNode;17;-2835.5,-109.7763;Inherit;False;1;0;FLOAT;0.25;False;1;FLOAT;0
Node;AmplifyShaderEditor.PannerNode;15;-2631.5,-249.7763;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0,-0.5;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;18;-2888.874,118.9304;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT;1;False;2;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.PannerNode;20;-2650.874,119.9304;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0,-0.5;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleTimeNode;19;-2854.874,259.9304;Inherit;False;1;0;FLOAT;0.5;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;33;-3589.001,24.42794;Inherit;False;30;RandomSwitch1;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;32;-3247.001,-19.57207;Inherit;False;3;0;FLOAT;0.85;False;1;FLOAT;1;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;35;-3230.001,138.4279;Inherit;False;3;0;FLOAT;0.75;False;1;FLOAT;1;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SinOpNode;43;-999.0109,1280.689;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SinOpNode;41;-997.0109,1375.689;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SinOpNode;40;-999.0109,1183.689;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleTimeNode;36;-1171.011,1183.689;Inherit;False;1;0;FLOAT;1.5;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleTimeNode;37;-1173.011,1280.689;Inherit;False;1;0;FLOAT;2;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleTimeNode;38;-1175.011,1463.689;Inherit;False;1;0;FLOAT;3;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleTimeNode;39;-1173.011,1375.689;Inherit;False;1;0;FLOAT;2.2;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;44;-766.0109,1185.689;Inherit;False;5;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;4;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SinOpNode;42;-998.0109,1461.689;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.FractNode;46;-557.0288,1186.111;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.StepOpNode;47;-415.0288,1185.111;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0.1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;48;-201.0288,1189.111;Inherit;False;SmallGlitchesSpawn;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.StepOpNode;50;-1674.648,1987.47;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;51;-1847.648,2183.47;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0.1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SinTimeNode;52;-2046.648,2111.47;Inherit;False;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.FractNode;53;-1831.648,2304.47;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;54;-1661.648,2305.47;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;20;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;56;-1292.648,2307.47;Inherit;False;BigGlitchedSpawn;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;57;-1234.759,2004.904;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;58;-1435.949,2006.694;Inherit;False;3;0;FLOAT;-0.075;False;1;FLOAT;0.075;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;59;-1232.949,2145.694;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;60;-1078.949,2005.694;Inherit;False;BigGlitches;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;61;-1069.949,2152.694;Inherit;False;BigGlitchesMask;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;79;-1740,512;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;82;-1820,416;Inherit;False;48;SmallGlitchesSpawn;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;81;-1532,480;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;80;-1989.396,551.9331;Inherit;False;31;RandomSwitch2;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;83;-1365.396,474.9331;Inherit;False;SmallGlitchesMask;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;62;-1914.631,-6.172363;Inherit;False;30;RandomSwitch1;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;64;-1529.631,-2.172363;Inherit;False;3;0;FLOAT;0.15;False;1;FLOAT;0.1;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.NegateNode;65;-1364.631,-1.172363;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;66;-1210.631,-246.1724;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;67;-1332.631,105.8276;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;70;-1036.631,-66.17236;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;63;-1403.631,222.8276;Inherit;False;31;RandomSwitch2;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;85;-796.8311,-61.06689;Inherit;False;SmallGlitches;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;87;-402.0713,1958.67;Inherit;False;85;SmallGlitches;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;88;-390.0713,2038.67;Inherit;False;60;BigGlitches;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;89;-143.0713,1990.67;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;90;-7.071289,1984.67;Inherit;False;CombinedGlitches;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;98;-5791.684,245.1158;Inherit;False;2;2;0;FLOAT4;0,0,0,0;False;1;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.UnityObjToClipPosHlpNode;96;-6282.57,243.8987;Inherit;False;1;0;FLOAT3;0,0,0;False;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ComputeScreenPosHlpNode;97;-6046.684,247.1158;Inherit;False;True;1;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.RangedFloatNode;100;-6108.684,440.1158;Inherit;False;Property;_GlitchesTiling;Glitches Tiling;7;0;Create;True;0;0;0;False;0;False;0.75;0.75;0;2;0;1;FLOAT;0
Node;AmplifyShaderEditor.Vector3Node;101;-6597.684,599.1157;Inherit;False;Constant;_Vector0;Vector 0;3;0;Create;True;0;0;0;False;0;False;0,0,0;0,0,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.UnityObjToClipPosHlpNode;102;-6362.626,606.5078;Inherit;False;1;0;FLOAT3;0,0,0;False;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ComputeScreenPosHlpNode;103;-6126.739,609.7247;Inherit;False;True;1;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;104;-5794.684,622.1157;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;105;-5478.685,442.1158;Inherit;False;2;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;106;-5149.685,441.1158;Inherit;False;2;2;0;FLOAT4;0,0,0,0;False;1;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.WorldSpaceCameraPos;107;-5992.174,773.3642;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.ObjectToWorldTransfNode;109;-5926.174,919.3641;Inherit;False;1;0;FLOAT4;0,0,0,1;False;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleSubtractOpNode;108;-5668.173,770.3642;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.DistanceOpNode;111;-5427.174,769.3642;Inherit;False;2;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0,0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.BreakToComponentsNode;112;-4991.961,434.5196;Inherit;True;FLOAT4;1;0;FLOAT4;0,0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.ScreenParams;115;-4982.961,706.5195;Inherit;False;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleDivideOpNode;116;-4793.961,726.5195;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;114;-4749.961,381.5196;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;113;-4543.96,435.5196;Inherit;False;FLOAT4;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;117;-4349.959,431.5196;Inherit;False;FixedScreenUVs;-1;True;1;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.GetLocalVarNode;119;-3389.971,-256.0031;Inherit;False;117;FixedScreenUVs;1;0;OBJECT;;False;1;FLOAT4;0
Node;AmplifyShaderEditor.WorldPosInputsNode;120;-3592.1,955.1953;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleTimeNode;121;-3631.406,1200.109;Inherit;False;1;0;FLOAT;0.05;False;1;FLOAT;0
Node;AmplifyShaderEditor.ComponentMaskNode;127;-3328.507,953.1096;Inherit;False;True;False;True;True;1;0;FLOAT3;0,0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;122;-3259.607,838.7088;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;124;-3284.313,765.908;Inherit;False;Property;_Panner1;Panner 1;8;0;Create;True;0;0;0;False;0;False;-1.5;-1.5;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;128;-3052.907,817.9089;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;125;-3257.008,1046.708;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;126;-3275.213,1141.607;Inherit;False;Property;_Panner2;Panner 2;9;0;Create;True;0;0;0;False;0;False;-1.5;-1.5;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;129;-3049.007,1042.808;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;136;-3084.108,607.3093;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;135;-3081.508,453.9091;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.Vector4Node;132;-3465.007,469.5099;Inherit;False;Property;_UVs1TilingxyScalezw;UVs 1 Tiling (xy) Scale (zw);11;0;Create;True;0;0;0;False;0;False;1,1,5,5;0,0,0,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.Vector4Node;134;-3457.209,1311.908;Inherit;False;Property;_UVs2TilingxyScalezw;UVs 2 Tiling (xy) Scale (zw);10;0;Create;True;0;0;0;False;0;False;2,2,5,5;0,0,0,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DynamicAppendNode;138;-3080.208,1419.807;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;137;-3077.606,1287.208;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;141;-2490.005,802.309;Inherit;False;UVs1;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;139;-2783.807,814.009;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;140;-2627.808,812.7092;Inherit;False;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;142;-2818.909,1070.759;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;143;-2662.91,1069.46;Inherit;False;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;144;-2517.306,1068.809;Inherit;False;UVs2;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.StepOpNode;55;-1513.648,2305.47;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0.9;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;22;-2268.207,98.26378;Inherit;True;Property;_glitchalpha1;glitchalpha;5;0;Create;True;0;0;0;False;0;False;-1;0b9c639a6f9ebd148979ec3984eeb5c2;0b9c639a6f9ebd148979ec3984eeb5c2;True;0;False;white;Auto;False;Instance;10;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;148;-5088.134,1315.013;Inherit;False;141;UVs1;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;149;-5087.474,1525.744;Inherit;False;144;UVs2;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.LerpOp;150;-4320.474,1409.744;Inherit;False;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;151;-4604.474,1769.745;Inherit;False;Property;_DistortionBlend;DistortionBlend;12;0;Create;True;0;0;0;False;0;False;0.7;0.7;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;152;-4131.474,1411.744;Inherit;False;Distortion;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SamplerNode;160;-4744.649,1312.639;Inherit;True;Property;_DistortionNormal;DistortionNormal;13;2;[HideInInspector];[NoScaleOffset];Create;True;0;0;0;False;0;False;-1;4759ebc96fa0cab4289256170b390446;4759ebc96fa0cab4289256170b390446;True;0;True;bump;Auto;True;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;161;-4753.649,1516.639;Inherit;True;Property;_DistortionNormal1;DistortionNormal;13;2;[HideInInspector];[NoScaleOffset];Create;True;0;0;0;False;0;False;-1;4759ebc96fa0cab4289256170b390446;4759ebc96fa0cab4289256170b390446;True;0;True;bump;Auto;True;Instance;160;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GrabScreenPosition;155;-5016.649,2084.639;Inherit;False;0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DynamicAppendNode;156;-4722.649,2112.639;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;157;-4436.649,2153.639;Inherit;False;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;159;-4719.449,2289.44;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;154;-5239.573,2280.406;Inherit;False;152;Distortion;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ComponentMaskNode;158;-5024.449,2281.44;Inherit;False;True;True;False;True;1;0;FLOAT3;0,0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;162;-4911.978,2436.929;Inherit;False;Constant;_Float0;Float 0;9;0;Create;True;0;0;0;False;0;False;0.1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;163;-4275.544,2154.282;Inherit;False;ScreenUV;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;45;-1142.011,1538.689;Inherit;False;Property;_GlitchedSpawSpeed;GlitchedSpawSpeed;6;0;Create;True;0;0;0;False;0;False;3;0;0;10;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;187;-5921.486,-1264.955;Inherit;False;61;BigGlitchesMask;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;186;-5933.486,-1365.955;Inherit;False;83;SmallGlitchesMask;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;189;-5688.486,-1325.955;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;190;-5562.486,-1320.955;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;196;-4805.913,-1388.84;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TextureCoordinatesNode;195;-4799.415,-1608.541;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TextureCoordinatesNode;197;-4859.211,-1170.441;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.NegateNode;192;-5214.709,-1338.651;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;194;-5051.709,-1343.651;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;193;-5074.909,-1125.651;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.Vector2Node;198;-5371.414,-1672.24;Inherit;False;Property;_EmissiveTiling;Emissive Tiling;17;0;Create;True;0;0;0;False;0;False;1,1;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.DynamicAppendNode;204;-3518.222,-1412.652;Inherit;True;FLOAT3;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;191;-5405.934,-1324.974;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0.075;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;205;-3207.628,-1406.789;Inherit;False;EmissionColor;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.LerpOp;202;-3746.858,-1251.998;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;201;-3731.28,-1499.051;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;200;-3731.917,-1735.203;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ScreenColorNode;165;-964.8366,-2478.707;Inherit;False;Global;_GrabScreen0;Grab Screen 0;9;0;Create;True;0;0;0;False;0;False;Object;-1;False;False;False;False;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;170;-1475.359,-2485.847;Inherit;False;163;ScreenUV;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;179;-1215.001,-2499.751;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT;1;False;2;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;166;-1797.541,-1740.864;Inherit;False;90;CombinedGlitches;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;180;-1459.523,-1741.907;Inherit;False;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;181;-1889.623,-1643.607;Inherit;False;Property;_RefractionOffset;Refraction Offset;15;0;Create;True;0;0;0;False;0;False;0.05;0;0;0.5;0;1;FLOAT;0
Node;AmplifyShaderEditor.NegateNode;182;-1303.365,-1738.273;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ComponentMaskNode;215;-4645.669,-3445.384;Inherit;False;True;True;False;False;1;0;FLOAT4;0,0,0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;214;-4913.531,-3442.02;Inherit;False;117;FixedScreenUVs;1;0;OBJECT;;False;1;FLOAT4;0
Node;AmplifyShaderEditor.DynamicAppendNode;218;-4125.071,-3344.47;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;219;-4367.262,-3332.136;Inherit;False;Property;_StripesSpeed;StripesSpeed;18;0;Create;True;0;0;0;False;0;False;-5;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleTimeNode;224;-4631.88,-3313.289;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.PannerNode;221;-4180.602,-3007.631;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;222;-4412.703,-3002.192;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;223;-4622.378,-2984.251;Inherit;False;Property;_PulseSpeed;PulseSpeed;22;0;Create;True;0;0;0;False;0;False;-0.75;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;212;-3774.017,-3849.231;Inherit;True;Property;_TextureSample0;Texture Sample 0;5;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Instance;10;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ScaleAndOffsetNode;217;-4283.843,-3831.292;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT;1;False;2;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;220;-4563.824,-3816.715;Inherit;False;Property;_StripesScale;StripesScale;20;0;Create;True;0;0;0;False;0;False;5;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.PannerNode;216;-4052.865,-3823.443;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TFHCRemapNode;229;-3355.921,-3783.89;Inherit;True;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;0;False;4;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;226;-4265.218,-4105.938;Inherit;False;Property;_StripesIntensity;StripesIntensity;24;0;Create;True;0;0;0;False;0;False;0.1;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;225;-4282.218,-4201.939;Inherit;False;Property;_OverallOpacity;OverallOpacity;23;0;Create;True;0;0;0;False;0;False;0.1;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;227;-3960.218,-4165.939;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ClampOpNode;228;-3705.547,-4182.352;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;210;-630.017,-2457.816;Inherit;True;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;211;-1068.091,-2282.046;Inherit;False;205;EmissionColor;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;242;-4307.329,-935.0405;Inherit;False;Constant;_EmissionBoost;EmissionBoost;20;0;Create;True;0;0;0;False;0;False;1;0;0;5;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;243;-4511.156,-992.1207;Inherit;False;233;PulseMask;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;199;-4051.804,-1807.317;Inherit;False;Property;_BaseColor;Base Color;21;0;Create;True;0;0;0;False;0;False;0.2941177,0.007843138,0.0509804,0;0.2941177,0.007843138,0.0509804,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;203;-3804.115,-952.1796;Inherit;False;Property;_EmissiveColor;Emissive Color;19;1;[HDR];Create;True;0;0;0;False;0;False;6.19,0.91,0.91,0;6.19,0.91,0.91,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.Vector4Node;244;-2838.704,3866.87;Inherit;False;Constant;_SpeedxStrenghtyFractUVz;Speed(x)Strenght(y)FractUV(z);22;0;Create;True;0;0;0;False;0;False;0.5,0.08,4,4;0,0,0,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleTimeNode;245;-2477.687,3747.655;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.FloorOpNode;246;-2302.687,3794.655;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCPixelate;249;-2058.687,3994.655;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;248;-2398.687,3992.655;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.PannerNode;250;-1765.687,4003.655;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;1,1;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;254;-2324.687,3601.655;Inherit;False;117;FixedScreenUVs;1;0;OBJECT;;False;1;FLOAT4;0
Node;AmplifyShaderEditor.ComponentMaskNode;255;-2091.687,3603.655;Inherit;False;True;True;False;False;1;0;FLOAT4;0,0,0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.PannerNode;252;-1845.187,3602.655;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;-1,-1;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.NoiseGeneratorNode;253;-1614.187,3600.655;Inherit;True;Simplex2D;True;False;2;0;FLOAT2;0,0;False;1;FLOAT;5;False;1;FLOAT;0
Node;AmplifyShaderEditor.NoiseGeneratorNode;251;-1534.687,4001.655;Inherit;True;Simplex2D;True;False;2;0;FLOAT2;0,0;False;1;FLOAT;5;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;257;-898.6868,3849.655;Inherit;True;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.NormalVertexDataNode;259;-870.6868,3636.655;Inherit;False;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;260;-629.6868,3847.655;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SamplerNode;213;-4003.457,-3040.026;Inherit;True;Property;_TextureSample1;Texture Sample 1;5;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Instance;10;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TFHCRemapNode;230;-3351.796,-3038.653;Inherit;True;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;0;False;4;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;231;-3387.361,-2758.479;Inherit;False;Property;_MinPulseOpacity;MinPulseOpacity;25;0;Create;True;0;0;0;False;0;False;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;232;-3387.361,-2671.479;Inherit;False;Constant;_MaxPulseOpacity;MaxPulseOpacity;19;0;Create;True;0;0;0;False;0;False;1;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SinTimeNode;265;-4148.056,-2783.396;Inherit;False;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.AbsOpNode;266;-3940.717,-2710.145;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.StaticSwitch;247;-2142.687,3745.655;Inherit;False;Property;_UseStepTime1;UseStepTime1;27;0;Create;True;0;0;0;False;0;False;0;0;0;True;;Toggle;2;Key0;Key1;Create;True;True;All;9;1;FLOAT;0;False;0;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT;0;False;7;FLOAT;0;False;8;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.StaticSwitch;256;-1271.687,3827.655;Inherit;False;Property;_UseFractionUUV1;UseFractionUUV 1;26;0;Create;True;0;0;0;False;0;False;0;0;0;True;;Toggle;2;Key0;Key1;Create;True;True;All;9;1;FLOAT;0;False;0;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT;0;False;7;FLOAT;0;False;8;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.StaticSwitch;264;-3681.717,-2977.839;Inherit;False;Property;_UseBreathPulse;Use Breath Pulse;29;0;Create;True;0;0;0;False;0;False;0;0;0;True;;Toggle;2;Key0;Key1;Create;True;True;All;9;1;FLOAT;0;False;0;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT;0;False;7;FLOAT;0;False;8;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;269;-3041.84,-2875.464;Inherit;False;Constant;_Float1;Float 1;27;0;Create;True;0;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;233;-2643.481,-3003.566;Inherit;False;PulseMask;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.StaticSwitch;268;-3014.84,-3013.464;Inherit;False;Property;_Keyword0;Keyword 0;26;0;Create;True;0;0;0;False;0;False;0;0;0;True;;Toggle;2;Key0;Key1;Reference;-1;True;True;All;9;1;FLOAT;0;False;0;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT;0;False;7;FLOAT;0;False;8;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;271;-6721.567,-2321.185;Inherit;False;Property;_FresnelScale;FresnelScale;31;0;Create;True;0;0;0;False;0;False;5;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;272;-6755.567,-2206.185;Inherit;False;Constant;_FresnelHardness;FresnelHardness;28;0;Create;True;0;0;0;False;0;False;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.FresnelNode;273;-6427.567,-2348.185;Inherit;False;Standard;WorldNormal;ViewDir;False;False;5;0;FLOAT3;0,0,1;False;4;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;5;False;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCRemapNode;274;-6414.436,-2171.739;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;0;False;4;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;275;-6157.079,-2301.934;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.StaticSwitch;276;-5955.079,-2313.934;Inherit;False;Property;_UseFresnel;Use Fresnel;32;0;Create;True;0;0;0;False;0;False;0;0;0;True;;Toggle;2;Key0;Key1;Create;True;True;All;9;1;FLOAT;0;False;0;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT;0;False;7;FLOAT;0;False;8;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;185;-4560.209,-1205.594;Inherit;True;Property;_EmissiveMap2;Emissive Map;16;1;[NoScaleOffset];Create;True;0;0;0;False;0;False;-1;d5a685f76510ca54da03f75379f2c0aa;d5a685f76510ca54da03f75379f2c0aa;True;1;False;white;Auto;False;Instance;183;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;239;-3964.277,-1614.128;Inherit;False;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;278;-4255.102,-1586.714;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;279;-4134.567,-1581.508;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;240;-3944.323,-1455.011;Inherit;False;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;280;-4229.835,-1448.111;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;281;-4109.3,-1442.905;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;282;-4261.394,-1160.518;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;283;-4140.858,-1155.312;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;241;-3931.155,-1250.68;Inherit;False;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.PosVertexDataNode;95;-6523.639,245.8746;Inherit;False;1;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.PosVertexDataNode;49;-2015.693,1941.351;Inherit;False;0;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.StaticSwitch;261;-476.6868,3838.655;Inherit;False;Property;_UseVertexDisplace1;Use Vertex Displace 1;28;0;Create;True;0;0;0;False;0;False;0;0;0;True;;Toggle;2;Key0;Key1;Create;True;True;All;9;1;FLOAT3;0,0,0;False;0;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;4;FLOAT3;0,0,0;False;5;FLOAT3;0,0,0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;262;-189.6868,3838.655;Inherit;False;VertNormalDisplace;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.CrossProductOpNode;176;-2278.91,-1500.005;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,1,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ViewDirInputsCoordNode;175;-2477.244,-1503.48;Inherit;False;World;True;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;168;-1243.741,-1375.165;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;309;-1014.775,-1491.159;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;305;-996.0753,-1342.161;Inherit;False;262;VertNormalDisplace;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleAddOpNode;310;-709.2753,-1491.159;Inherit;True;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SamplerNode;183;-4557.389,-1622.224;Inherit;True;Property;_EmissiveRVertDispMaskG;Emissive(R)VertDispMask(G);16;1;[NoScaleOffset];Create;True;0;0;0;False;0;False;-1;d5a685f76510ca54da03f75379f2c0aa;d5a685f76510ca54da03f75379f2c0aa;True;1;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.NegateNode;178;-1820.91,-1501.005;Inherit;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;234;-2651.694,-3780.049;Inherit;False;StripeMask;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;238;-1060.642,-2205.735;Inherit;False;234;StripeMask;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.StaticSwitch;270;-2972.688,-3778.842;Inherit;False;Property;_GlobalOpacityPulse;Global Opacity Pulse;30;0;Create;True;0;0;0;False;0;False;0;1;1;True;;Toggle;2;Key0;Key1;Create;True;True;All;9;1;FLOAT;0;False;0;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT;0;False;7;FLOAT;0;False;8;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;267;-3063.814,-3623.08;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;313;-122.4419,-1862.606;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;1;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;ExtraPrePass;0;0;ExtraPrePass;5;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;5;True;12;all;0;False;True;1;1;False;;0;False;;0;1;False;;0;False;;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;True;True;True;True;0;False;;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;True;1;False;;True;3;False;;True;True;0;False;;0;False;;True;0;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;315;-122.4419,-1862.606;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;1;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;ShadowCaster;0;2;ShadowCaster;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;5;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;False;False;True;False;False;False;False;0;False;;False;False;False;False;False;False;False;False;False;True;1;False;;True;3;False;;False;True;1;LightMode=ShadowCaster;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;316;-122.4419,-1862.606;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;1;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;DepthOnly;0;3;DepthOnly;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;5;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;False;False;True;False;False;False;False;0;False;;False;False;False;False;False;False;False;False;False;True;1;False;;False;False;True;1;LightMode=DepthOnly;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;317;-122.4419,-1862.606;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;1;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;Meta;0;4;Meta;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;5;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;2;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=Meta;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;318;-122.4419,-1862.606;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;1;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;Universal2D;0;5;Universal2D;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;5;True;12;all;0;False;True;1;1;False;;0;False;;0;1;False;;0;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;True;True;True;True;0;False;;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;True;1;False;;True;3;False;;True;True;0;False;;0;False;;True;1;LightMode=Universal2D;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;319;-122.4419,-1862.606;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;1;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;SceneSelectionPass;0;6;SceneSelectionPass;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;5;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;2;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=SceneSelectionPass;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;320;-122.4419,-1862.606;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;1;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;ScenePickingPass;0;7;ScenePickingPass;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;5;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=Picking;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;321;-122.4419,-1862.606;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;1;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;DepthNormals;0;8;DepthNormals;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;5;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;False;;True;3;False;;False;True;1;LightMode=DepthNormalsOnly;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;322;-122.4419,-1862.606;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;1;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;DepthNormalsOnly;0;9;DepthNormalsOnly;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;5;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;False;;True;3;False;;False;True;1;LightMode=DepthNormalsOnly;False;True;9;d3d11;metal;vulkan;xboxone;xboxseries;playstation;ps4;ps5;switch;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;314;-122.4419,-1862.606;Float;False;True;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;13;AS_Glitch;2992e84f91cbeb14eab234972e07ea9d;True;Forward;0;1;Forward;8;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Transparent=RenderType;Queue=Transparent=Queue=0;True;7;True;12;all;0;False;True;1;5;False;;10;False;;1;1;False;;10;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;True;True;True;True;0;False;;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;True;True;1;False;;True;3;False;;True;True;0;False;;0;False;;True;1;LightMode=UniversalForwardOnly;False;False;0;;0;0;Standard;23;Surface;1;638471505389752874;  Blend;0;0;Two Sided;1;0;Forward Only;0;0;Cast Shadows;1;0;  Use Shadow Threshold;0;0;Receive Shadows;1;0;GPU Instancing;1;0;LOD CrossFade;0;0;Built-in Fog;0;0;DOTS Instancing;0;0;Meta Pass;0;0;Extra Pre Pass;0;0;Tessellation;1;638471505844706018;  Phong;0;0;  Strength;0.5,False,;0;  Type;0;0;  Tess;32,False,;638471506146911784;  Min;10,False,;0;  Max;25,False,;0;  Edge Length;16,False,;0;  Max Displacement;25,False,;0;Vertex Position,InvertActionOnDeselection;1;0;0;10;False;True;True;True;False;False;True;True;True;False;False;;False;0
Node;AmplifyShaderEditor.SamplerNode;184;-4573.209,-1414.594;Inherit;True;Property;_EmissiveMap1;Emissive Map;16;1;[NoScaleOffset];Create;True;0;0;0;False;0;False;-1;d5a685f76510ca54da03f75379f2c0aa;d5a685f76510ca54da03f75379f2c0aa;True;1;False;white;Auto;False;Instance;183;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.NormalizeNode;177;-2094.91,-1501.005;Inherit;True;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;167;-1585.641,-1326.264;Inherit;False;Property;_GlitchDisplacementStrenght;Glitch Displacement Strenght;14;0;Create;True;0;0;0;False;0;False;1;1;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.NormalizeNode;323;-257.6323,-1506.5;Inherit;False;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SamplerNode;10;-2287.428,-274.5407;Inherit;True;Property;_MaskMap;MaskMap;5;2;[HideInInspector];[NoScaleOffset];Create;True;0;0;0;False;0;False;-1;0b9c639a6f9ebd148979ec3984eeb5c2;0b9c639a6f9ebd148979ec3984eeb5c2;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;258;-1290.687,3578.655;Inherit;True;Property;_TextureSample2;Texture Sample 2;16;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Instance;183;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
WireConnection;29;0;25;0
WireConnection;28;0;29;0
WireConnection;25;0;24;4
WireConnection;27;0;25;0
WireConnection;31;0;27;0
WireConnection;30;0;28;0
WireConnection;14;0;119;0
WireConnection;16;0;14;0
WireConnection;16;1;32;0
WireConnection;15;0;16;0
WireConnection;15;1;17;0
WireConnection;18;0;14;0
WireConnection;18;1;35;0
WireConnection;20;0;18;0
WireConnection;20;1;19;0
WireConnection;32;2;33;0
WireConnection;35;2;33;0
WireConnection;43;0;37;0
WireConnection;41;0;39;0
WireConnection;40;0;36;0
WireConnection;44;0;40;0
WireConnection;44;1;43;0
WireConnection;44;2;41;0
WireConnection;44;3;42;0
WireConnection;44;4;45;0
WireConnection;42;0;38;0
WireConnection;46;0;44;0
WireConnection;47;0;46;0
WireConnection;48;0;47;0
WireConnection;50;0;49;2
WireConnection;50;1;51;0
WireConnection;51;0;52;4
WireConnection;53;0;52;4
WireConnection;54;0;53;0
WireConnection;56;0;55;0
WireConnection;57;0;58;0
WireConnection;57;1;55;0
WireConnection;58;2;50;0
WireConnection;59;0;50;0
WireConnection;59;1;55;0
WireConnection;60;0;57;0
WireConnection;61;0;59;0
WireConnection;79;0;10;1
WireConnection;79;1;22;1
WireConnection;79;2;80;0
WireConnection;81;0;82;0
WireConnection;81;1;79;0
WireConnection;83;0;81;0
WireConnection;64;2;62;0
WireConnection;65;0;64;0
WireConnection;66;0;10;1
WireConnection;66;1;65;0
WireConnection;67;0;64;0
WireConnection;67;1;22;1
WireConnection;70;0;66;0
WireConnection;70;1;67;0
WireConnection;70;2;63;0
WireConnection;85;0;70;0
WireConnection;89;0;87;0
WireConnection;89;1;88;0
WireConnection;90;0;89;0
WireConnection;98;0;97;0
WireConnection;98;1;100;0
WireConnection;96;0;95;0
WireConnection;97;0;96;0
WireConnection;102;0;101;0
WireConnection;103;0;102;0
WireConnection;104;0;100;0
WireConnection;104;1;103;0
WireConnection;105;0;98;0
WireConnection;105;1;104;0
WireConnection;106;0;105;0
WireConnection;106;1;111;0
WireConnection;108;0;107;0
WireConnection;108;1;109;0
WireConnection;111;0;108;0
WireConnection;112;0;106;0
WireConnection;116;0;115;1
WireConnection;116;1;115;2
WireConnection;114;0;112;0
WireConnection;114;1;116;0
WireConnection;113;0;114;0
WireConnection;113;1;112;1
WireConnection;113;2;112;2
WireConnection;113;3;112;3
WireConnection;117;0;113;0
WireConnection;127;0;120;0
WireConnection;122;0;121;0
WireConnection;122;1;124;0
WireConnection;128;0;127;0
WireConnection;128;1;122;0
WireConnection;125;0;121;0
WireConnection;125;1;126;0
WireConnection;129;0;127;0
WireConnection;129;1;125;0
WireConnection;136;0;132;3
WireConnection;136;1;132;4
WireConnection;135;0;132;1
WireConnection;135;1;132;2
WireConnection;138;0;134;3
WireConnection;138;1;134;4
WireConnection;137;0;134;1
WireConnection;137;1;134;2
WireConnection;141;0;140;0
WireConnection;139;0;128;0
WireConnection;139;1;135;0
WireConnection;140;0;139;0
WireConnection;140;1;136;0
WireConnection;142;0;129;0
WireConnection;142;1;137;0
WireConnection;143;0;142;0
WireConnection;143;1;138;0
WireConnection;144;0;143;0
WireConnection;55;0;54;0
WireConnection;22;1;20;0
WireConnection;150;0;160;0
WireConnection;150;1;161;0
WireConnection;150;2;151;0
WireConnection;152;0;150;0
WireConnection;160;1;148;0
WireConnection;161;1;149;0
WireConnection;156;0;155;1
WireConnection;156;1;155;2
WireConnection;157;0;156;0
WireConnection;157;1;159;0
WireConnection;159;0;158;0
WireConnection;159;1;162;0
WireConnection;158;0;154;0
WireConnection;163;0;157;0
WireConnection;189;0;186;0
WireConnection;189;1;187;0
WireConnection;190;0;189;0
WireConnection;196;0;198;0
WireConnection;196;1;194;0
WireConnection;195;0;198;0
WireConnection;197;0;198;0
WireConnection;197;1;193;0
WireConnection;192;0;191;0
WireConnection;194;0;192;0
WireConnection;193;0;191;0
WireConnection;204;0;200;0
WireConnection;204;1;201;0
WireConnection;204;2;202;0
WireConnection;191;0;190;0
WireConnection;205;0;204;0
WireConnection;202;0;199;3
WireConnection;202;1;203;3
WireConnection;202;2;241;0
WireConnection;201;0;199;2
WireConnection;201;1;203;2
WireConnection;201;2;240;0
WireConnection;200;0;199;1
WireConnection;200;1;203;1
WireConnection;200;2;239;0
WireConnection;165;0;179;0
WireConnection;179;0;170;0
WireConnection;179;2;182;0
WireConnection;180;0;166;0
WireConnection;180;1;181;0
WireConnection;180;2;178;0
WireConnection;182;0;180;0
WireConnection;215;0;214;0
WireConnection;218;1;219;0
WireConnection;221;0;215;0
WireConnection;221;2;222;0
WireConnection;221;1;224;0
WireConnection;222;1;223;0
WireConnection;212;1;216;0
WireConnection;217;0;215;0
WireConnection;217;1;220;0
WireConnection;216;0;217;0
WireConnection;216;2;218;0
WireConnection;216;1;224;0
WireConnection;229;0;212;3
WireConnection;229;3;228;0
WireConnection;229;4;225;0
WireConnection;227;0;225;0
WireConnection;227;1;226;0
WireConnection;228;0;227;0
WireConnection;228;2;225;0
WireConnection;210;0;165;0
WireConnection;210;1;211;0
WireConnection;210;2;238;0
WireConnection;245;0;244;1
WireConnection;246;0;245;0
WireConnection;249;0;248;0
WireConnection;249;1;244;3
WireConnection;249;2;244;4
WireConnection;250;0;249;0
WireConnection;250;1;247;0
WireConnection;255;0;254;0
WireConnection;252;0;255;0
WireConnection;252;1;247;0
WireConnection;253;0;252;0
WireConnection;251;0;250;0
WireConnection;257;0;258;2
WireConnection;257;1;256;0
WireConnection;257;2;244;2
WireConnection;260;0;259;0
WireConnection;260;1;257;0
WireConnection;213;1;221;0
WireConnection;230;0;264;0
WireConnection;230;3;231;0
WireConnection;230;4;232;0
WireConnection;266;0;265;4
WireConnection;247;1;245;0
WireConnection;247;0;246;0
WireConnection;256;1;253;0
WireConnection;256;0;251;0
WireConnection;264;1;213;2
WireConnection;264;0;266;0
WireConnection;233;0;268;0
WireConnection;268;1;230;0
WireConnection;268;0;269;0
WireConnection;273;2;271;0
WireConnection;274;0;272;0
WireConnection;275;0;273;0
WireConnection;275;1;274;0
WireConnection;276;0;275;0
WireConnection;185;1;197;0
WireConnection;239;0;279;0
WireConnection;239;1;243;0
WireConnection;239;2;242;0
WireConnection;278;0;183;1
WireConnection;278;1;276;0
WireConnection;279;0;278;0
WireConnection;240;0;281;0
WireConnection;240;1;243;0
WireConnection;240;2;242;0
WireConnection;280;0;184;1
WireConnection;280;1;276;0
WireConnection;281;0;280;0
WireConnection;282;0;185;1
WireConnection;282;1;276;0
WireConnection;283;0;282;0
WireConnection;241;0;283;0
WireConnection;241;1;243;0
WireConnection;241;2;242;0
WireConnection;261;0;260;0
WireConnection;262;0;261;0
WireConnection;176;0;175;0
WireConnection;168;0;166;0
WireConnection;168;1;167;0
WireConnection;309;0;178;0
WireConnection;309;1;168;0
WireConnection;310;0;309;0
WireConnection;310;1;305;0
WireConnection;183;1;195;0
WireConnection;178;0;177;0
WireConnection;234;0;270;0
WireConnection;270;1;229;0
WireConnection;270;0;267;0
WireConnection;267;0;229;0
WireConnection;267;1;230;0
WireConnection;314;2;210;0
WireConnection;314;5;310;0
WireConnection;314;6;323;0
WireConnection;184;1;196;0
WireConnection;177;0;176;0
WireConnection;323;0;310;0
WireConnection;10;1;15;0
ASEEND*/
//CHKSM=A07DE8B72A2BD5472F6CFA497D04082CD7A05B01