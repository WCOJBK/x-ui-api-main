import requests
from typing import Any, Dict
import base64
from urllib.parse import urlparse


def _b64_to_bytes(b64: str):
	"""尝试将标准/URL Base64(可无填充)解码为原始字节。失败则返回 None。"""
	b64 = (b64 or "").strip()
	if not b64:
		return None
	# 尝试标准 Base64
	try:
		pad = '=' * ((4 - len(b64) % 4) % 4)
		return base64.b64decode(b64 + pad)
	except Exception:
		pass
	# 尝试 URL-safe Base64
	try:
		pad = '=' * ((4 - len(b64) % 4) % 4)
		return base64.urlsafe_b64decode(b64 + pad)
	except Exception:
		return None


def _to_base64url_no_padding(b64: str) -> str:
	"""把任意变体Base64规范成URL-safe且无填充。若失败则原样返回。"""
	raw = _b64_to_bytes(b64)
	if raw is None:
		return b64
	return base64.urlsafe_b64encode(raw).decode('ascii').rstrip('=')


class XUIClient:
	def __init__(self, base_url: str, enhanced_api_url: str = None) -> None:
		self.base_url = base_url.rstrip('/')
		# 如果提供了增强API地址，使用它；否则从原生面板地址推断（端口+6027）
		if enhanced_api_url:
			self.enhanced_api_url = enhanced_api_url.rstrip('/')
		else:
			# 自动推断增强API地址：假设是面板端口+6027（如2053->8080）
			parsed = urlparse(self.base_url)
			enhanced_port = 8080  # 默认增强API端口
			if parsed.port:
				enhanced_port = 8080  # 简化假设，使用固定端口8080
			self.enhanced_api_url = f"{parsed.scheme}://{parsed.hostname}:{enhanced_port}"
		
		self.session = requests.Session()
		# 禁用系统代理，避免被本机/网络代理拦截导致 200 空响应
		self.session.trust_env = False
		self._last_debug: Dict[str, Any] = {}
		# 默认请求头，便于通过 checkLogin 的 AJAX 判定
		parsed = urlparse(self.base_url)
		origin = f"{parsed.scheme}://{parsed.netloc}"
		self.session.headers.update({
			"X-Requested-With": "XMLHttpRequest",
			"Content-Type": "application/json",
			"Referer": self.base_url,
			"Origin": origin,
		})

	def get_last_http_debug(self) -> Dict[str, Any]:
		return dict(self._last_debug)

	def _post_json(self, path: str, payload: Dict[str, Any] | None = None) -> Dict[str, Any]:
		url = f"{self.base_url}{path}"
		try:
			resp = self.session.post(url, json=payload)
		except Exception as e:
			self._last_debug = {"error": str(e), "url": url}
			return {"success": False, "msg": str(e)}
		# 记录调试信息
		try:
			req = resp.request
			body = req.body
			if isinstance(body, bytes):
				body = body.decode('utf-8', errors='ignore')
			self._last_debug = {
				"method": req.method if req else "POST",
				"url": req.url if req else url,
				"requestHeaders": dict(req.headers) if req else dict(self.session.headers),
				"requestBodyPreview": (str(body)[:400] if body else ""),
				"status": resp.status_code,
				"finalURL": resp.url,
				"responseHeaders": dict(resp.headers),
				"contentType": resp.headers.get("Content-Type", ""),
				"history": [{"status": r.status_code, "location": r.headers.get("Location", "")} for r in resp.history],
				"textPreview": resp.text[:400],
			}
		except Exception:
			self._last_debug = {"method": "POST", "url": url, "status": resp.status_code}
		# 返回结果
		if resp.status_code == 200:
			try:
				return resp.json()
			except Exception:
				return {"success": False, "msg": "Non-JSON response", "status": resp.status_code}
		return {"success": False, "msg": resp.text, "status": resp.status_code}

	def _post_json_enhanced(self, path: str, payload: Dict[str, Any] | None = None) -> Dict[str, Any]:
		"""使用增强API发送POST JSON请求"""
		url = f"{self.enhanced_api_url}{path}"
		try:
			resp = self.session.post(url, json=payload)
		except Exception as e:
			self._last_debug = {"error": str(e), "url": url}
			return {"success": False, "msg": str(e)}
		# 记录调试信息
		try:
			req = resp.request
			body = req.body
			if isinstance(body, bytes):
				body = body.decode('utf-8', errors='ignore')
			self._last_debug = {
				"method": req.method if req else "POST",
				"url": req.url if req else url,
				"requestHeaders": dict(req.headers) if req else dict(self.session.headers),
				"requestBodyPreview": (str(body)[:400] if body else ""),
				"status": resp.status_code,
				"finalURL": resp.url,
				"responseHeaders": dict(resp.headers),
				"contentType": resp.headers.get("Content-Type", ""),
				"history": [{"status": r.status_code, "location": r.headers.get("Location", "")} for r in resp.history],
				"textPreview": resp.text[:400],
			}
		except Exception:
			self._last_debug = {"method": "POST", "url": url, "status": resp.status_code}
		# 返回结果
		if resp.status_code == 200:
			try:
				return resp.json()
			except Exception:
				return {"success": False, "msg": "Non-JSON response", "status": resp.status_code}
		return {"success": False, "msg": resp.text, "status": resp.status_code}

	def login(self, username: str, password: str, login_secret: str = "") -> bool:
		resp = self.session.post(f"{self.base_url}/login", data={
			"username": username,
			"password": password,
			"loginSecret": login_secret,
		})
		# 记录登录调试
		try:
			req = resp.request
			self._last_debug = {
				"method": req.method if req else "POST",
				"url": req.url if req else f"{self.base_url}/login",
				"requestHeaders": dict(req.headers) if req else dict(self.session.headers),
				"status": resp.status_code,
				"finalURL": resp.url,
				"responseHeaders": dict(resp.headers),
				"setCookie": resp.headers.get("Set-Cookie", ""),
				"textPreview": resp.text[:200],
			}
		except Exception:
			pass
		# 面板登录无论成功失败都返回 200，需要看 JSON 的 success 字段
		try:
			data = resp.json()
			return bool(data.get("success"))
		except Exception:
			return False

	def list_inbounds(self) -> Any:
		resp = self.session.post(f"{self.base_url}/panel/api/inbound/list")
		if resp.status_code != 200:
			resp = self.session.get(f"{self.base_url}/panel/api/inbounds/list")
		return resp.json() if resp.ok else {"success": False, "msg": resp.text}

	def update_inbound(self, inbound_id: int, updated_data: Dict[str, Any]) -> Dict[str, Any]:
		"""更新指定入站配置"""
		resp = self.session.post(f"{self.base_url}/panel/api/inbounds/update/{inbound_id}", json=updated_data)
		return resp.json() if resp.ok else {"success": False, "msg": resp.text}

	# ---------------- 出站管理（使用增强API模拟端点） ----------------
	def list_outbounds(self) -> Any:
		return self._post_json_enhanced("/panel/api/enhanced/tools/simulate/outbounds/list")

	def add_outbound(self, outbound: Dict[str, Any]) -> Dict[str, Any]:
		return self._post_json_enhanced("/panel/api/enhanced/tools/simulate/outbounds/add", outbound)

	def update_outbound(self, tag: str, outbound: Dict[str, Any]) -> Dict[str, Any]:
		return self._post_json_enhanced("/panel/api/enhanced/tools/simulate/outbounds/update", {"tag": tag, "outbound": outbound})

	def delete_outbound(self, tag: str) -> Dict[str, Any]:
		return self._post_json_enhanced("/panel/api/enhanced/tools/simulate/outbounds/delete", {"tag": tag})

	# ---------------- 路由管理（使用增强API模拟端点） ----------------
	def get_routing(self) -> Any:
		return self._post_json_enhanced("/panel/api/enhanced/tools/simulate/routing/get")

	def update_routing(self, routing: Dict[str, Any]) -> Dict[str, Any]:
		return self._post_json_enhanced("/panel/api/enhanced/tools/simulate/routing/update", routing)

	def add_route_rule(self, rule: Dict[str, Any]) -> Dict[str, Any]:
		return self._post_json_enhanced("/panel/api/enhanced/tools/simulate/routing/rule/add", rule)

	def delete_route_rule(self, index: int) -> Dict[str, Any]:
		return self._post_json_enhanced("/panel/api/enhanced/tools/simulate/routing/rule/delete", {"index": index})

	def update_route_rule(self, index: int, rule: Dict[str, Any]) -> Dict[str, Any]:
		return self._post_json_enhanced("/panel/api/enhanced/tools/simulate/routing/rule/update", {"index": index, "rule": rule})

	def add_vless_reality_template(self, port: int, uuid: str, sni: str, private_key: str, public_key: str, short_id: str, email: str = "reality@example.com", total_gb: int = 0, expiry_time: int = 0, limit_ip: int = 0) -> Dict[str, Any]:
		"""使用模板方式创建VLESS Reality入站（基于成功的端口20297配置）"""
		import json
		
		# 完全复制手动创建成功的配置模板
		# 统一将私钥转为 URL-safe Base64(无填充)
		private_key_url = _to_base64url_no_padding(private_key)
		template_config = {
			"remark": f"vless-reality-{port}",
			"enable": True,
			"expiryTime": expiry_time,
			"listen": None,  # 与模板一致
			"port": port,
			"protocol": "vless",
			"settings": json.dumps({
				"clients": [{
					"email": email,
					"flow": "xtls-rprx-vision",
					"id": uuid,
					"totalGB": total_gb * 1024 * 1024 * 1024 if total_gb > 0 else 0,
					"expiryTime": expiry_time,
					"limitIp": limit_ip,
					"enable": True
				}],
				"decryption": "none",
				"fallbacks": []
			}),
			"sniffing": json.dumps({
				"destOverride": ["http", "tls", "quic", "fakedns"],
				"enabled": False,  # 注意：模板中是false
				"metadataOnly": False,
				"routeOnly": False
			}),
			"streamSettings": json.dumps({
				"network": "tcp",
				"realitySettings": {
					"dest": f"{sni}:443",
					"maxClient": "",
					"maxTimediff": 0,
					"minClient": "",
					"privateKey": private_key_url,
					# 注意：3X-UI 前端读取的是 realitySettings.settings.publicKey
					"settings": {
						"publicKey": public_key,
						"fingerprint": "chrome",
						"serverName": sni,
						"spiderX": "/"
					},
					"serverNames": [sni, f"www.{sni}"],
					"shortIds": [short_id],
					"show": False,
					"xver": 0
				},
				"security": "reality",
				"tcpSettings": {
					"acceptProxyProtocol": False,
					"header": {
						"type": "none"
					}
				}
			}),
			"allocate": json.dumps({
				"concurrency": 3,
				"refresh": 5,
				"strategy": "always"
			})
		}
		
		resp = self.session.post(f"{self.base_url}/panel/api/inbounds/add", json=template_config)
		return resp.json() if resp.ok else {"success": False, "msg": resp.text}

	def add_vless_reality(self, port: int, uuid: str, sni: str, private_key: str, short_id: str, email: str = "reality@example.com", total_gb: int = 0, expiry_time: int = 0, limit_ip: int = 0, public_key: str = "") -> Dict[str, Any]:
		"""标准方式创建VLESS Reality入站"""
		# 如果有公钥，使用模板方式创建（更可靠）
		if public_key:
			return self.add_vless_reality_template(port, uuid, sni, private_key, public_key, short_id, email, total_gb, expiry_time, limit_ip)
		
		import json
		
		settings = {
			"clients": [{
				"id": uuid, 
				"email": email, 
				"flow": "xtls-rprx-vision", 
				"enable": True,
				"totalGB": total_gb * 1024 * 1024 * 1024 if total_gb > 0 else 0,  # GB转字节
				"expiryTime": expiry_time,
				"limitIp": limit_ip
			}],
			"decryption": "none",
			"fallbacks": []  # 添加缺失的fallbacks字段
		}
		# 将hex私钥转换为base64格式（与手动创建一致）
		try:
			# 如果是hex格式，转换为base64
			if len(private_key) == 64 and all(c in '0123456789abcdefABCDEF' for c in private_key):
				priv_bytes = bytes.fromhex(private_key)
				private_key_b64 = base64.b64encode(priv_bytes).decode('ascii')
			else:
				# 假设已经是base64格式
				private_key_b64 = private_key
		except:
			private_key_b64 = private_key

		# 统一将私钥转为 URL-safe Base64(无填充)
		private_key_url = _to_base64url_no_padding(private_key_b64)
		
		stream = {
			"network": "tcp",
			"security": "reality",
			"realitySettings": {
				"show": False,
				"dest": f"{sni}:443",
				"xver": 0,
				"maxClient": "",
				"maxTimediff": 0, 
				"minClient": "",
				"serverNames": [sni, f"www.{sni}"],
				"privateKey": private_key_url,  # 使用URL-safe无填充格式
				# 注意：3X-UI 前端读取的是 realitySettings.settings.publicKey
				"settings": {
					"publicKey": public_key,
					"fingerprint": "chrome",
					"serverName": sni,
					"spiderX": "/"
				},
				"shortIds": [short_id],
			},
			"tcpSettings": {
				"acceptProxyProtocol": False,
				"header": {
					"type": "none"
				}
			}
		}
		sniff = {
			"enabled": True, 
			"destOverride": ["http", "tls", "quic", "fakedns"], 
			"metadataOnly": False,
			"routeOnly": False
		}
		
		# 添加allocate配置（与手动创建一致）
		allocate = {
			"concurrency": 3,
			"refresh": 5,
			"strategy": "always"
		}
		
		# 修复：将JSON对象转换为字符串
		payload = {
			"remark": f"vless-reality-{port}",
			"enable": True,
			"expiryTime": 0,
			"listen": "",
			"port": port,
			"protocol": "vless",
			"settings": json.dumps(settings),      # 转为JSON字符串
			"streamSettings": json.dumps(stream),  # 转为JSON字符串
			"sniffing": json.dumps(sniff),         # 转为JSON字符串
			"allocate": json.dumps(allocate),      # 添加allocate配置
		}
		resp = self.session.post(f"{self.base_url}/panel/api/inbounds/add", json=payload)
		return resp.json() if resp.ok else {"success": False, "msg": resp.text}

class EnhancedAPIClient:
	def __init__(self, base_url: str) -> None:
		self.base_url = base_url.rstrip('/')
		self.session = requests.Session()

	def health(self) -> Any:
		return self.session.get(f"{self.base_url}/health").json()

	def traffic_summary(self, period: str = "week") -> Any:
		return self.session.get(f"{self.base_url}/panel/api/enhanced/stats/traffic/summary/{period}").json()

	def system_health(self) -> Any:
		return self.session.get(f"{self.base_url}/panel/api/enhanced/monitor/health/system").json()

	def generate_reality_keys(self) -> Any:
		"""调用服务器生成Reality密钥"""
		resp = self.session.get(f"{self.base_url}/panel/api/enhanced/tools/generate-reality-keys")
		return resp.json() if resp.ok else {"success": False, "msg": resp.text, "status": resp.status_code}

	def get_xray_info(self) -> Any:
		"""获取服务器xray信息"""
		resp = self.session.get(f"{self.base_url}/panel/api/enhanced/tools/xray-info")
		return resp.json() if resp.ok else {"success": False, "msg": resp.text}

	def validate_keys(self, private_key: str, public_key: str) -> Any:
		"""验证密钥格式"""
		resp = self.session.post(f"{self.base_url}/panel/api/enhanced/tools/validate-reality-keys", 
								json={"privateKey": private_key, "publicKey": public_key})
		return resp.json() if resp.ok else {"success": False, "msg": resp.text}
