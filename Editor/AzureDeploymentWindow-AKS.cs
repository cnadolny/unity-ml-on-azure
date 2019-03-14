using System;
using System.IO;
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
    string jobRunID = $"run-a";

    string environmentFile;

    string cmd;

    void OnGUI()
    {
        EditorGUILayout.LabelField("Train ML on Azure", EditorStyles.boldLabel);
        storageAccountName = EditorGUILayout.TextField("Storage Account Name", 
            storageAccountName,
            new GUILayoutOption[]
            {
                GUILayout.ExpandWidth(true),
                GUILayout.MinWidth(200)
            });
        jobRunID = EditorGUILayout.TextField("Job Name (Run ID)", 
            jobRunID,
            new GUILayoutOption[]
            {
                GUILayout.ExpandWidth(true),
                GUILayout.MinWidth(200)
            });

        if (EditorGUILayout.DropdownButton(new GUIContent(environmentFile ?? "Choose Build Output"), FocusType.Keyboard))
        {
            environmentFile = EditorUtility.OpenFilePanel("Select Build Output", Directory.GetCurrentDirectory(), "x86_64");
        }

        if (!string.IsNullOrEmpty(cmd))
        {
            // The intent is that we'd run the process ourselves, either by shelling out to the script or by using Azure SDKs from
            // within the editor. For now, just learning about custom Unity editor windows, so putting something on the screen.
            GUILayout.Label("Run this command from the console:");

            var originalWrap = EditorStyles.label.wordWrap;
            EditorStyles.label.wordWrap = true;

            EditorGUILayout.SelectableLabel(
                cmd,
                new GUILayoutOption[]
                {
                    GUILayout.ExpandHeight(true),
                    GUILayout.MinHeight(75)
                });

            EditorStyles.label.wordWrap = originalWrap;
        }

        GUILayout.FlexibleSpace();
        
        if (GUILayout.Button(new GUIContent("Generate Deployment Command")))
        {
            cmd = $".\\scripts\\train-on-aks.ps1 -storageAccountName {storageAccountName} -environmentName {Path.GetFileNameWithoutExtension(environmentFile)} -localVolume {Path.GetDirectoryName(environmentFile)} -runid {jobRunID}";
        }
    }
}
