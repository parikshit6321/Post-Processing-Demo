using UnityEngine;
using System.Collections;
using UnityStandardAssets.ImageEffects;
using UnityStandardAssets.CinematicEffects;

public class PostProcessingControl : MonoBehaviour {

    private bool bPostProcessing = true;

	// Use this for initialization
	void Start () {
        
    }
	
    private void TogglePostProcessing() {

        bPostProcessing = !bPostProcessing;

        if(bPostProcessing) {

            // Enable all the effects
            if (GetComponent<Camera>().GetComponent<Bloom>() != null)
                GetComponent<Camera>().GetComponent<Bloom>().enabled = true;

            if (GetComponent<Camera>().GetComponent<GodRays>() != null)
                GetComponent<Camera>().GetComponent<GodRays>().enabled = true;

            if (GetComponent<Camera>().GetComponent<Vignette>() != null)
                GetComponent<Camera>().GetComponent<Vignette>().enabled = true;

            if (GetComponent<Camera>().GetComponent<CustomLensFlare>() != null)
                GetComponent<Camera>().GetComponent<CustomLensFlare>().enabled = true;

            if (GetComponent<Camera>().GetComponent<ToneMapping>() != null)
                GetComponent<Camera>().GetComponent<ToneMapping>().enabled = true;

            if (GetComponent<Camera>().GetComponent<BokehDOF>() != null)
                GetComponent<Camera>().GetComponent<BokehDOF>().enabled = true;

            if (GetComponent<Camera>().GetComponent<ScreenSpaceAmbientOcclusion>() != null)
                GetComponent<Camera>().GetComponent<ScreenSpaceAmbientOcclusion>().enabled = true;

            if (GetComponent<Camera>().GetComponent<AntiAliasing>() != null)
                GetComponent<Camera>().GetComponent<AntiAliasing>().enabled = true;
        }
        else {

            // Disable all the effects
            if (GetComponent<Camera>().GetComponent<Bloom>() != null)
                GetComponent<Camera>().GetComponent<Bloom>().enabled = false;

            if (GetComponent<Camera>().GetComponent<GodRays>() != null)
                GetComponent<Camera>().GetComponent<GodRays>().enabled = false;

            if (GetComponent<Camera>().GetComponent<Vignette>() != null)
                GetComponent<Camera>().GetComponent<Vignette>().enabled = false;

            if (GetComponent<Camera>().GetComponent<CustomLensFlare>() != null)
                GetComponent<Camera>().GetComponent<CustomLensFlare>().enabled = false;

            if (GetComponent<Camera>().GetComponent<ToneMapping>() != null)
                GetComponent<Camera>().GetComponent<ToneMapping>().enabled = false;

            if (GetComponent<Camera>().GetComponent<BokehDOF>() != null)
                GetComponent<Camera>().GetComponent<BokehDOF>().enabled = false;

            if (GetComponent<Camera>().GetComponent<ScreenSpaceAmbientOcclusion>() != null)
                GetComponent<Camera>().GetComponent<ScreenSpaceAmbientOcclusion>().enabled = false;

            if (GetComponent<Camera>().GetComponent<AntiAliasing>() != null)
                GetComponent<Camera>().GetComponent<AntiAliasing>().enabled = false;

        }
    }

    // Called once per frame
    void Update() {

        if (Input.anyKeyDown)
        {
            TogglePostProcessing();
            return;
        }
        if(Input.touchCount > 0)
        {
            if(Input.GetTouch(0).phase == TouchPhase.Began)
            {
                TogglePostProcessing();
            }
        }
    }
}
