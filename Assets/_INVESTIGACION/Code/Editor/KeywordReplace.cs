/*-----------------------------
 -------------------------------
 Creation Date: #CREATIONDATE#
 Author: #DEVELOPER#
 Description: #PROJECTNAME#
--------------------------------
-----------------------------*/

using UnityEngine;
using UnityEditor;
using System.IO;

public class KeywordReplace : UnityEditor.AssetModificationProcessor {
	public static void OnWillCreateAsset(string path)
	{
		path = path.Replace(".meta", "");
		int index = path.LastIndexOf("");
		if (index < 0) return;

		string file = path.Substring(index);
		if (file != ".cs" && file != ".js" && file != ".boo") return;

		index = Application.dataPath.LastIndexOf("Asset");
		path = Application.dataPath.Substring(0, index) + path;
		if (!File.Exists(path)) return;

		string fileContent = File.ReadAllText(path);

		fileContent = fileContent.Replace("#CEATIONDATE#", System.DateTime.Today.ToString("dd/MM/yy") + "");
		fileContent = fileContent.Replace("#PROJECTNAME#", PlayerSettings.productName);
		fileContent = fileContent.Replace("#DEVELOPER#", System.Environment.UserName);

		File.WriteAllText(path, fileContent);
		AssetDatabase.Refresh();
	}
}