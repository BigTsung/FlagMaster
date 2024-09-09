using UnityEngine;
using UnityEngine.UI;

public class ScrollingBackground : MonoBehaviour
{
    public float scrollSpeed = 0.5f;  // 滾動速度
    private Material bgMaterial;

    void Start()
    {
        // 取得 Image 的材質
        Image image = GetComponent<Image>();
        if (image != null)
        {
            bgMaterial = image.material;
        }
        else
        {
            Debug.LogError("Image component not found on the game object.");
        }
    }

    void Update()
    {
        if (bgMaterial != null)
        {
            // 計算滾動偏移
            float offset = Time.time * scrollSpeed;
            bgMaterial.mainTextureOffset = new Vector2(offset, 0);  // 水平滾動
        }
    }
}