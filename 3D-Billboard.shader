Shader "MyroP/3D-Billboard"
{
	Properties
	{
		_MainTex("Main texture", 2D) = "white" {}
		_ThicknessFlatSide("Thickness on the flat side", Range(0.0, 1.0)) = 0.005
		_ThicknessLargerSide("Thickness on the larger side", Range(0.0, 3.0)) = 1.0
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
			#define HALFPI 1.57079632675
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

				///the code bellow starts the billboard effect

				//we get the current position of the vertex in local space
				float4 vertex = v.vertex;

				//we get the camera position in world space
				#if UNITY_SINGLE_PASS_STEREO
					//The user is in VR
					//To avoid getting a weird 3D effect in VR, since there are two cameras in VR, we'll basically say that the camera is between both eyes...
					float3 cameraPositionWS = (unity_StereoWorldSpaceCameraPos[0] + unity_StereoWorldSpaceCameraPos[1]) / 2;
				#else
					//The user is on Desktop
					float3 cameraPositionWS = _WorldSpaceCameraPos;
				#endif

				//We convert the world space camera position to local space
				float3 cameraPosLS = cameraPositionWS - mul(unity_ObjectToWorld, float4(0,0,0,1));
		
				//the vertex might have a rotation, we remove that rotation
				float meshAngleY = atan2(unity_ObjectToWorld._m02_m12_m22.z,unity_ObjectToWorld._m02_m12_m22.x) + HALFPI;
				float3 rotationAxisY = {0,1,0};
				Unity_RotateAboutAxis_Radians_float(cameraPosLS, rotationAxisY, meshAngleY, cameraPosLS);

				//Now we will snap the vertex on a flat plane
				//To make the math a bit easier, I decided to only work with the x and z values, so only the x and z coordinates of the vertex will be modified
				float2 vertex2DSpace = {vertex.x, vertex.z};
				float2 cameraPos2DSpace = {cameraPosLS.x, cameraPosLS.z};
				cameraPos2DSpace = normalize(cameraPos2DSpace);
		
				//cameraPos2DSpace is the camera position in local space without the y value, we want to snap each vertex on a perpendicular plane
				float2 perpendicular2DPlaneDirection = {cameraPos2DSpace.y, -cameraPos2DSpace.x};
		
				//and here we do the math to snap the vertex on the plane
				float dotProduct = dot(perpendicular2DPlaneDirection,vertex2DSpace); //dot product of the vertex and the perpendicular place
				float2 newPosition = perpendicular2DPlaneDirection * dotProduct; //the new position is on the plane
				newPosition -= (newPosition - vertex2DSpace) * _ThicknessFlatSide; //but there's an issue, if we snap everything on a plane there will be z-fighting issues, so we need to separate the vertex a little bit from the plane
				newPosition += perpendicular2DPlaneDirection * dotProduct * (_ThicknessLargerSide - 1.0); //just for fun, the vertex can be put closer or further to the center here,, to make the final mesh larger or narrower...

				//now we just need to show it on the viewport
				vertex.x = newPosition.x;
				vertex.z = newPosition.y;
				vertex = UnityWorldToClipPos(mul (unity_ObjectToWorld, vertex));

				//end of the code that snaps the vertex on a plane

				o.pos = vertex; 
				o.color = v.color;
				o.uv_MainTex = TRANSFORM_TEX(v.texcoord, _MainTex);

				return o;
			}

			sampler2D _MainTex;

			float4 frag(v2f IN) : COLOR
			{
				half4 c = tex2D(_MainTex, IN.uv_MainTex);
				return  c;
			}

			ENDCG
		}
	}
}
