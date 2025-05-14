# 推送到 GitHub 的说明

要将此项目推送到 GitHub，请按照以下步骤操作：

1. 创建 GitHub 仓库（如果尚未创建）
2. 添加远程仓库：

   ```bash
   git remote add origin <你的GitHub仓库URL>
   ```

3. 推送 main 分支：

   ```bash
   git push -u origin main
   ```

4. 推送标签以触发自动发布：
   ```bash
   git push origin v1.2.0
   ```

推送标签后，GitHub Actions 将自动创建一个新的发布，并将 server_analyzer.sh 和 README 文件作为附件。

## 更新项目

当您对脚本进行更改并准备发布新版本时：

1. 在 server_analyzer.sh 中更新 VERSION 变量
2. 提交更改：

   ```bash
   git add .
   git commit -m "更新到版本 x.y.z"
   ```

3. 创建新标签：

   ```bash
   git tag -a vx.y.z -m "服务器分析工具 vx.y.z发布"
   ```

4. 推送更改和标签：
   ```bash
   git push origin main
   git push origin vx.y.z
   ```
