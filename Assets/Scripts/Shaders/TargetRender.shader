Shader "Custom/TargetRender"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
        _TestHitPos ("TestHitPos", Vector) = (1, 1, 0, 0)
        _ScaleFactor("ScaleFactor", Float) = 3.
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Standard fullforwardshadows

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        #define BM0 1876811222u
        #define BM1 2364525772u
        #define BM2 1876739647u
        #define BM3 1876716758u
        #define BM4 3722439884u
        #define BM5 4051684567u
        #define BM6 3325550070u
        #define BM7 4241388339u
        #define BM8 1876291030u
        #define BM9 1876814947u

        const uint digits[10] = {
            BM0, BM1, BM2, BM3, BM4,
            BM5, BM6, BM7, BM8, BM9
        };

        sampler2D _MainTex;

        struct Input
        {
            float2 uv_MainTex;
        };

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;
        fixed2 _TestHitPos;
        fixed _ScaleFactor;
        
        uniform int _Scores[5];

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

        fixed dSqrt(fixed2 val) {
            return dot(val, val);
        }

        float bitsToGrid(in fixed2 gid, in uint bitMsk) {
            uint bitIdx = uint(gid.x + gid.y * 4.);
            uint bit = (bitMsk & (1u << bitIdx));
            return min(1., fixed(bit));
        }

        float scores(in fixed2 st) 
        {
            const uint digits[10] = {
                BM0, BM1, BM2, BM3, BM4,
                BM5, BM6, BM7, BM8, BM9
            };
            
            fixed scale = 64.;
            fixed2 uv = st + fixed2(.7, .31);
            fixed2 p = uv * scale;
            fixed2 gst = .5 - frac(p);
            fixed2 gid = floor(p);

            fixed2 tuv = p * fixed2(.25, .125);
            fixed2 tgv = frac(tuv);
            fixed2 tid = floor(tuv);
            fixed value = 1. - dSqrt(gst * 1.8);

            int bmIdx = _Scores[int(fmod((tid.x * .333 - 3.), 10.))];
            uint bitmap = digits[bmIdx];
            value *= bitsToGrid(
                gid - fixed2(0, tid.x), bitmap
            );

            value *= step(10., tid.x);
            value *= step(tid.x, 24.);
            value *= step(2., tid.y);
            value *= step(tid.y, 2.);

            value *= step(2., tid.x % 3.);

            return value;
        }

        fixed sdHexagram(in fixed2 p, in fixed r)
        {
            const fixed4 k = fixed4(
                -0.5, 0.8660254038, 0.5773502692, 1.7320508076
                );
            p = abs(p);
            p -= 2.0 * min(dot(k.xy, p), 0.0) * k.xy;
            p -= 2.0 * min(dot(k.yx, p), 0.0) * k.yx;
            p -= fixed2(clamp(p.x, r * k.z, r * k.w), r);
            return length(p) * sign(p.y);
        }

        fixed3 getColor (fixed2 uv ) 
        {
            fixed t = _Time.y;
            fixed sf = _ScaleFactor;
            fixed2 p = uv * sf - sf * .5; 
            fixed g = max(0., -sdHexagram(p, .8) * 5.);
            fixed rg = frac(g);
            fixed ri = floor(g);
            fixed d = sdHexagram(p, rg);
            fixed scrs = scores(p);
            fixed hit = 1. - smoothstep(0, .01, length(p + _TestHitPos.xy) - .01);
            
            fixed3 col = 1. - d;
            fixed outl = smoothstep(.0, .1, abs(rg - .05));
            
            col = min(col, ri * .08);
            col += (1. - outl) * col;
            col += max(
                sin(rg - t) * .15 + .15,
                scrs * (frac(pow(p.x * .5, 2.) - t * 2.) + .5)
            );
            col = lerp(col, hit, hit);
            return col;
        }

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            fixed2 uv = IN.uv_MainTex;
            fixed4 c = tex2D(_MainTex, uv) * _Color;
            o.Albedo = getColor(uv);
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = c.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
