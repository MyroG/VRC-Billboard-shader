Shader "MyroP/Billboard"
{
	Properties
	{
		_MainTex("Main texture", 2D) = "white" {}
		_ThicknessFlatSide("Thickness on the flat side", Range(0.001, 1.0)) = 0.001
		_ThicknessLargerSide("Thickness on the larger side", Range(0.001, 3.0)) = 1.0
	}

	SubShader
	{
		Tags
		{ 
			"RenderType" = "Opaque"
		}
		LOD 200

		Pass
		{
			Lighting On
			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			struct v2f
			{
				fixed4 pos : SV_POSITION;
				half4 color : COLOR0;
				float2 uv_MainTex : TEXCOORD0;
				half3 normal : TEXCOORD1;
			}; 

			float4 _MainTex_ST;
			float _ThicknessFlatSide;
			float _ThicknessLargerSide;

			void Unity_RotateAboutAxis_Radians_float(float3 In, float3 Axis, float Rotation, out float3 Out)
			{
				float s = sin(Rotation);
				float c = cos(Rotation);
				float one_minus_c = 1.0 - c;

				Axis = normalize(Axis);
				float3x3 rot_mat = 
				{   one_minus_c * Axis.x * Axis.x + c, one_minus_c * Axis.x * Axis.y - Axis.z * s, one_minus_c * Axis.z * Axis.x + Axis.y * s,
					one_minus_c * Axis.x * Axis.y + Axis.z * s, one_minus_c * Axis.y * Axis.y + c, one_minus_c * Axis.y * Axis.z - Axis.x * s,
					one_minus_c * Axis.z * Axis.x - Axis.y * s, one_minus_c * Axis.y * Axis.z + Axis.x * s, one_minus_c * Axis.z * Axis.z + c
				};
				Out = mul(rot_mat,  In);
			}

			v2f vert(appdata_full v)
			{
				v2f o;

				//Vertex snapping
				float4 vertex = v.vertex;

				//camera distance from the vertex
				#if UNITY_SINGLE_PASS_STEREO
					//To avoid getting a weird stereotoscopic effect in VR, where the mesh on the left and right eye looks different...
					float3 cameraPosition = (unity_StereoWorldSpaceCameraPos[0] + unity_StereoWorldSpaceCameraPos[1]) / 2;
				#else
					float3 cameraPosition = _WorldSpaceCameraPos;
				#endif

				float3 cameraPosWP = cameraPosition - mul(unity_ObjectToWorld, float4(0,0,0,1));
		
				//get current Y rotation of the mesh
				float meshAngleY = atan2(unity_ObjectToWorld._m02_m12_m22.z,unity_ObjectToWorld._m02_m12_m22.x);
				float3 rotationAxisY = {0,1,0};
				Unity_RotateAboutAxis_Radians_float(cameraPosWP, rotationAxisY, meshAngleY, cameraPosWP);

				//We will work will x and z
				float2 vertex2DSpace = {vertex.x, vertex.z};
		
				//we don't need the y value
				float2 cameraPos2DSpace = {cameraPosWP.x, cameraPosWP.z};
				cameraPos2DSpace = normalize(cameraPos2DSpace);
		
				float2 perpendicular2DPlaneDirection = {-cameraPos2DSpace.x, cameraPos2DSpace.y};
		
				float dotProduct = dot(vertex2DSpace, perpendicular2DPlaneDirection);
				float2 newPosition = perpendicular2DPlaneDirection * dotProduct;
				newPosition -= (newPosition - vertex2DSpace) * _ThicknessFlatSide;
				newPosition += perpendicular2DPlaneDirection * dotProduct * (_ThicknessLargerSide - 1.0);

				vertex.x = newPosition.x;
				vertex.z = newPosition.y;
				vertex = UnityWorldToClipPos(mul (unity_ObjectToWorld, vertex));
		
				o.pos = vertex; 

				o.color = v.color;
				o.uv_MainTex = TRANSFORM_TEX(v.texcoord, _MainTex);

				return o;
			}

			sampler2D _MainTex;

			float4 frag(v2f IN) : COLOR
			{
				half4 c = tex2D(_MainTex, IN.uv_MainTex)*IN.color;
				return  c;
			}

			ENDCG
		}
	}
}