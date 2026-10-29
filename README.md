# Python Xray-Argo for Nhost Run

本项目基于原版 [python-xray-argo](https://github.com/eooce/python-xray-argo) 修改，专门适配 **Nhost Run**（https://app.nhost.io），可在 Nhost 平台以自定义容器方式运行，并输出可用节点。

支持协议：VLESS-WS-TLS / VMess-WS-TLS / Trojan-WS-TLS（通过 Cloudflare Argo 隧道），可选 Hysteria2 / Reality / Socks5。

## 在 Nhost 上部署步骤

### 1. 创建 Nhost 项目
1. 打开 https://app.nhost.io 登录并创建新项目。
2. 进入项目后，找到 **Run** 功能（或 Services）。

### 2. 构建并推送镜像（推荐）

在本地（已安装 Docker 和 Nhost CLI）执行：

```bash
# 登录 Nhost（如果还没登录）
nhost login

# 配置 Docker 凭据（推送到 Nhost 私有 registry）
nhost docker-credentials configure

# 构建并推送（把 <region> 和 <project-id> 换成你的）
# 示例：registry.eu-central-1.nhost.run/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/xray-argo:latest
docker buildx build --platform linux/amd64 \
  -t registry.<region>.nhost.run/<your-project-id>/xray-argo:latest \
  --push .
```

> 也可以直接在 Nhost 仪表盘创建 Run Service，选择「从 Dockerfile 构建」或上传镜像。

### 3. 创建 Run Service 配置

使用本仓库的 `nhost-run-service.toml`，或在仪表盘手动创建：

- **Name**: `xray-argo`
- **Image**: 你刚推送的镜像地址
- **Port**: `3000`，类型 `http`，勾选 **Publish**
- **Resources**: 建议 CPU ≥ 500m，Memory ≥ 512Mi
- **Environment Variables**（在仪表盘或 toml 中设置）：

| 变量名 | 是否必须 | 默认值 | 说明 |
|--------|----------|--------|------|
| `UUID` | 推荐 | 随机 | 节点 UUID，建议自定义 |
| `NAME` | 推荐 | 空 | 节点名称前缀，例如 `Nhost` |
| `PORT` | 否 | 3000 | HTTP 订阅端口（需与 toml 中一致） |
| `FILE_PATH` | 否 | /tmp/.cache | 运行时文件目录 |
| `SUB_PATH` | 否 | sub | 订阅路径，访问 `/sub` 获取节点 |
| `CFIP` | 否 | cf.877774.xyz | 优选 IP/域名 |
| `CFPORT` | 否 | 443 | 优选端口 |
| `ARGO_DOMAIN` | 否 | 空 | 固定隧道域名（留空用临时隧道） |
| `ARGO_AUTH` | 否 | 空 | 固定隧道 token/json |
| `NEZHA_SERVER` | 否 | 空 | 哪吒面板地址 |
| `NEZHA_KEY` | 否 | 空 | 哪吒密钥 |
| `CHAT_ID` / `BOT_TOKEN` | 否 | 空 | Telegram 推送节点 |
| `PROJECT_URL` | 否 | 空 | 你的 Run Service 公网 URL（用于保活） |
| `AUTO_ACCESS` | 否 | false | 是否开启自动保活 |
| `SHOW_LOG` | 否 | true | 是否输出详细日志 |

### 4. 部署

使用 CLI：

```bash
nhost run config-deploy --config nhost-run-service.toml --service-id <service-id>
```

或在仪表盘点击 Deploy / Apply。

### 5. 获取节点

部署成功后：

1. 在 Nhost Run Service 详情页查看 **Public URL**（类似 `https://xxxx.run.nhost.run`）。
2. 访问：
   ```
   https://你的-public-url/sub
   ```
   即可得到 base64 或明文节点列表（默认路径 `/sub`，可通过 `SUB_PATH` 修改）。
3. 查看容器日志（Logs），也会打印生成的节点信息。
4. 如果配置了 Telegram，节点会自动推送到你的 Bot。

**非标端口订阅示例**（如果平台分配了端口）：
```
http://你的域名:端口/sub
```

## 本地测试

```bash
# 安装依赖
pip install -r requirements.txt

# 运行
python3 app.py

# 访问 http://localhost:3000/sub
```

或使用 Docker：

```bash
docker build -t xray-argo .
docker run -p 3000:3000 -e UUID=your-uuid -e NAME=Test xray-argo
```

## 注意事项

1. **临时隧道 vs 固定隧道**：默认使用 Cloudflare 临时隧道（每次重启域名会变）。生产环境建议配置 `ARGO_DOMAIN` + `ARGO_AUTH` 使用固定隧道。
2. **资源**：Xray + Cloudflared 需要一定内存，建议至少 512MB。
3. **持久化**：默认使用 `/tmp/.cache`，容器重启后文件丢失（节点链接本身不依赖本地文件）。如需持久化可在 toml 中添加 storage。
4. **哪吒探针**：支持 v0 / v1，按环境变量填写即可。
5. **免责**：本程序仅供学习交流，请遵守当地法律法规，作者不承担任何责任。

## 文件说明

- `app.py`：主程序
- `Dockerfile`：容器构建文件（Alpine 基础，兼容原版二进制）
- `nhost-run-service.toml`：Nhost Run 服务配置模板
- `requirements.txt`：Python 依赖

## 原项目

原版地址：https://github.com/eooce/python-xray-argo  
直连版本：https://github.com/eoovve/python-xray-direct
