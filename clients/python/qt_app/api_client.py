import requests
from typing import Any, Dict

class XUIClient:
	def __init__(self, base_url: str) -> None:
		self.base_url = base_url.rstrip('/')
		self.session = requests.Session()

	def login(self, username: str, password: str) -> bool:
		resp = self.session.post(f"{self.base_url}/login", data={
			"username": username,
			"password": password,
		})
		return resp.status_code == 200

	def list_inbounds(self) -> Any:
		resp = self.session.post(f"{self.base_url}/panel/api/inbound/list")
		if resp.status_code != 200:
			resp = self.session.get(f"{self.base_url}/panel/api/inbounds/list")
		return resp.json() if resp.ok else {"success": False, "msg": resp.text}

	def update_inbound(self, inbound_id: int, updated_data: Dict[str, Any]) -> Dict[str, Any]:
		"""更新指定入站配置"""
		resp = self.session.post(f"{self.base_url}/panel/api/inbounds/update/{inbound_id}", json=updated_data)
		return resp.json() if resp.ok else {"success": False, "msg": resp.text}

	def add_vless_reality(self, port: int, uuid: str, sni: str, private_key: str, short_id: str, email: str = "reality@example.com", total_gb: int = 0, expiry_time: int = 0, limit_ip: int = 0, public_key: str = "") -> Dict[str, Any]:
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
		import base64
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
				"privateKey": private_key_b64,  # 使用base64格式
				"publicKey": public_key,        # 添加公钥字段
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
