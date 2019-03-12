using System;
using UnityEditor;
using UnityEngine;

public class AzureDeploymentWindow : EditorWindow
{
    [MenuItem("ML on Azure/Train")]
    static void OnAzureLogin()
    {
        EditorWindow.GetWindow(typeof(AzureDeploymentWindow), false, "Train ML on Azure", true);
    }

    // TODO: Good enough for initial POC. Not good enough to ship. 
    // 1. Should remember the user's storage acct name once set, or let them select from a dropdown using Azure SDKs to populate from their subscription
    // 2. This default wouldn't be globally unique at scale
    string storageAccountName = $"unityml{DateTime.Now.ToString("yyyyMMddHHmm")}";

    string environmentFile;

    string cmd;

    void OnGUI()
    {
        EditorGUILayout.LabelField("Train ML on Azure", EditorStyles.boldLabel);
        storageAccountName = EditorGUILayout.TextField("Storage account name", storageAccountName);

        if (EditorGUILayout.DropdownButton(new GUIContent(environmentFile ?? "Choose build output"), FocusType.Keyboard))
        {
            environmentFile = EditorUtility.OpenFilePanel("Select build output", Directory.GetCurrentDirectory(), "x86_64");
        }

        if (!string.IsNullOrEmpty(cmd))
        {
            // The intent is that we'd run the process ourselves, either by shelling out to the script or by using Azure SDKs from
            // within the editor. For now, just learning about custom Unity editor windows, so putting something on the screen.
            GUILayout.Label("Run this:");

            var originalWrap = EditorStyles.label.wordWrap;
            EditorStyles.label.wordWrap = true;

            EditorGUILayout.SelectableLabel(
                cmd,
                new GUILayoutOption[]
                {
                    GUILayout.ExpandHeight(true),
                    GUILayout.MinHeight(50)
                });

            EditorStyles.label.wordWrap = originalWrap;
        }

        GUILayout.FlexibleSpace();
        
        if (GUILayout.Button(new GUIContent("Deploy")))
        {
            cmd = $".\\train-on-aks.ps1 -storageAccountName {storageAccountName} -environmentName {Path.GetFileNameWithoutExtension(environmentFile)} -localVolume {Path.GetDirectoryName(environmentFile)}";
        }
    }
}
