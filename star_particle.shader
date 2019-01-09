Shader "Unlit/star_particle"
{
	Properties
	{
        //テクスチャ読み込み
        //whiteはデフォルトカラー
		_Pos ("Pos", 2D) = "white" {}
		_Col ("Col", 2D) = "white" {}
		_Mag ("Mag", 2D) = "white" {}
		_Mag_param ("Star brightness", Range(0, 500)) = 200
		_Mag_min ("min brightness", Range(0, 1)) = 0.05
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma geometry geom
			#pragma fragment frag
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};
            
            //構造体
			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
				float3 color : TEXCOORD1;
			};
            
            //Propertiesは再び宣言する必要あり
			sampler2D _Pos;
			sampler2D _Col;
			sampler2D _Mag;
			float _Mag_param;
			float _Mag_min;
			
            //今回はgeomで処理するので頂点データを横流し
            //本来はfragに橋渡しする作業
			appdata vert (appdata v)
			{
				return v;
			}
            
            //テクスチャからfloat値を取り出す
			float3 unpack(float2 uv) {
				float texWidth = 2048.0;
				float2 e = float2(-1.0/texWidth/2, 1.0/texWidth/2);
				uint3 v0 = uint3(tex2Dlod(_Pos, float4(uv + e.xy,0,0)).xyz * 255.) << 0;
				uint3 v1 = uint3(tex2Dlod(_Pos, float4(uv + e.yy,0,0)).xyz * 255.) << 8;
				uint3 v2 = uint3(tex2Dlod(_Pos, float4(uv + e.xx,0,0)).xyz * 255.) << 16;
				uint3 v3 = uint3(tex2Dlod(_Pos, float4(uv + e.yx,0,0)).xyz * 255.) << 24;
				uint3 v = v0 + v1 + v2 + v3;
				return asfloat(v);
			}
            
			[maxvertexcount(3)]
			void geom(triangle appdata IN[3], inout TriangleStream<v2f> stream) {
				float2 uv = (IN[0].uv + IN[1].uv + IN[2].uv) / 3;
				uv.x = (floor(uv.x * 1024) + 0.5) / 1024.0;
				uv.y = (floor(uv.y * 1024) + 0.5) / 1024.0;
				
				float3 p = unpack(uv).xzy;
				float3 c = tex2Dlod(_Col, float4(uv,0,0)).xyz;
				if(length(p) < 0.1 && length(c) < 0.1) return;
				
				float sz = tex2Dlod(_Mag, float4(uv,0,0)).x * _Mag_param + _Mag_min;
				sz *= pow(determinant((float3x3)UNITY_MATRIX_M),1/3.0);
				float aspectRatio = - UNITY_MATRIX_P[0][0] / UNITY_MATRIX_P[1][1];
				v2f o;
				float4 vp1 = UnityObjectToClipPos(float4(p, 1));
				
				o.color = c;
				o.uv = float2(0,1);
				o.vertex = vp1+float4(o.uv*sz*float2(aspectRatio,1),0,0);
				stream.Append(o);
				o.uv = float2(-0.9,-0.5);
				o.vertex = vp1+float4(o.uv*sz*float2(aspectRatio,1),0,0);
				stream.Append(o);
				o.uv = float2(0.9,-0.5);
				o.vertex = vp1+float4(o.uv*sz*float2(aspectRatio,1),0,0);
				stream.Append(o);
				stream.RestartStrip();
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				float l = length(i.uv);
				clip(0.5-l);
				return float4(i.color,1);
			}
			ENDCG
		}
	}
}
