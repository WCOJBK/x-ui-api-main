import sys
import uuid
import secrets
from PySide6.QtWidgets import (
	QApplication, QWidget, QTabWidget, QVBoxLayout, QFormLayout, QLineEdit,
	QPushButton, QLabel, QHBoxLayout, QSpinBox, QTextEdit, QMessageBox, QCheckBox, QFileDialog
)
from PySide6.QtCore import Qt, QSettings
from api_client import XUIClient, EnhancedAPIClient

# 新增: 本地生成Reality密钥用
try:
	from cryptography.hazmat.primitives.asymmetric import x25519
	from cryptography.hazmat.primitives import serialization
	_HAS_CRYPTO = True
except Exception:
	_HAS_CRYPTO = False

HEX = "0123456789abcdef"

def _b64_to_bytes_any(b64: str) -> bytes:
    import base64
    s = (b64 or "").strip()
    if not s:
        raise ValueError("empty base64 input")
    pad = '=' * ((4 - len(s) % 4) % 4)
    # try standard
    try:
        return base64.b64decode(s + pad)
    except Exception:
        pass
    # try urlsafe
    try:
        return base64.urlsafe_b64decode(s + pad)
    except Exception as e:
        raise e

def gen_uuid() -> str:
	return str(uuid.uuid4())

def gen_short() -> str:
	return "".join(secrets.choice(HEX) for _ in range(16))

def gen_tag(prefix: str = "proxy-") -> str:
	return prefix + "".join(secrets.choice(HEX) for _ in range(8))

class LoginPane(QWidget):
	def __init__(self) -> None:
		super().__init__()
		self.xui_url = QLineEdit("http://127.0.0.1:2053")
		self.enh_url = QLineEdit("http://127.0.0.1:8080")
		self.user = QLineEdit("admin")
		self.passwd = QLineEdit("admin")
		self.passwd.setEchoMode(QLineEdit.Password)
		self.remember = QCheckBox("保存登录信息")
		self.remember.setChecked(True)
		self.btn = QPushButton("登录3X-UI")
		self.status = QLabel("")
		form = QFormLayout()
		form.addRow("面板地址", self.xui_url)
		form.addRow("增强API", self.enh_url)
		form.addRow("用户名", self.user)
		form.addRow("密码", self.passwd)
		layout = QVBoxLayout(self)
		layout.addLayout(form)
		layout.addWidget(self.remember)
		layout.addWidget(self.btn)
		layout.addWidget(self.status)

class InboundPane(QWidget):
	def __init__(self) -> None:
		super().__init__()
		self.list_btn = QPushButton("查询入站")
		self.out = QTextEdit(); self.out.setReadOnly(True)
		# create form
		self.port = QSpinBox(); self.port.setRange(1, 65535); self.port.setValue(443)
		self.uuid = QLineEdit(gen_uuid())
		self.sni = QLineEdit("yahoo.com")
		self.host = QLineEdit("yahoo.com")
		self.short = QLineEdit(gen_short())
		self.priv = QLineEdit("")
		self.email = QLineEdit(f"reality_{secrets.randbelow(999999)}@example.com")
		# 新增: 流量控制和到期时间
		self.total_gb = QSpinBox(); self.total_gb.setRange(0, 10000); self.total_gb.setValue(100); self.total_gb.setSuffix(" GB")
		self.expiry_days = QSpinBox(); self.expiry_days.setRange(0, 3650); self.expiry_days.setValue(30); self.expiry_days.setSuffix(" 天")
		self.limit_ip = QSpinBox(); self.limit_ip.setRange(0, 100); self.limit_ip.setValue(2)
		self.create_btn = QPushButton("创建 VLESS+Reality 入站")
		# 新增: 本地生成按钮与公钥显示、复制链接
		self.gen_btn = QPushButton("生成 Reality 密钥对")
		self.pub_out = QLineEdit("")
		self.pub_out.setReadOnly(True)
		self.copy_btn = QPushButton("复制 VLESS 链接到剪贴板")
		form = QFormLayout()
		form.addRow("端口", self.port)
		form.addRow("UUID", self.uuid)
		form.addRow("SNI/Target", self.sni)
		form.addRow("主机(客户端地址)", self.host)
		form.addRow("shortId", self.short)
		form.addRow("私钥", self.priv)
		form.addRow("公钥(只读,客户端用)", self.pub_out)
		form.addRow("Email", self.email)
		form.addRow("流量限制", self.total_gb)
		form.addRow("有效期", self.expiry_days)
		form.addRow("IP限制", self.limit_ip)
		layout = QVBoxLayout(self)
		layout.addWidget(self.list_btn)
		layout.addWidget(self.out)
		layout.addLayout(form)
		# 新增: 生成与复制按钮
		btn_layout = QHBoxLayout()
		btn_layout.addWidget(self.gen_btn)
		self.server_gen_btn = QPushButton("🌐 服务器生成密钥")
		btn_layout.addWidget(self.server_gen_btn)
		self.template_btn = QPushButton("📋 使用模板密钥")
		btn_layout.addWidget(self.template_btn)
		self.manual_btn = QPushButton("✏️ 手动填入密钥")
		btn_layout.addWidget(self.manual_btn)
		self.debug_btn = QPushButton("🔍 调试xray")
		btn_layout.addWidget(self.debug_btn)
		btn_layout.addWidget(self.copy_btn)
		layout.addLayout(btn_layout)
		layout.addWidget(self.create_btn)
		
		# 新增: 刷新按钮（重新生成UUID和Email避免冲突）
		self.refresh_btn = QPushButton("🔄 刷新UUID和Email")
		layout.addWidget(self.refresh_btn)
		
		# 新增: 验证按钮（检查数据库实际存储）
		self.verify_btn = QPushButton("🔍 验证最新入站配置")
		layout.addWidget(self.verify_btn)

class MonitorPane(QWidget):
	def __init__(self) -> None:
		super().__init__()
		self.refresh = QPushButton("刷新健康与统计")
		self.out = QTextEdit(); self.out.setReadOnly(True)
		layout = QVBoxLayout(self)
		layout.addWidget(self.refresh)
		layout.addWidget(self.out)

class OutboundPane(QWidget):
	def __init__(self) -> None:
		super().__init__()
		self.out = QTextEdit(); self.out.setReadOnly(True)
		self.tag = QLineEdit("")
		self.protocol = QLineEdit("")
		self.body = QTextEdit("")
		self.body.setPlaceholderText('{"settings": {...}} 或完整出站JSON')
		self.refresh_btn = QPushButton("刷新出站")
		self.add_btn = QPushButton("新增出站")
		self.update_btn = QPushButton("更新出站")
		self.delete_btn = QPushButton("删除出站")
		self.quick_line = QLineEdit("")
		self.quick_line.setPlaceholderText("host:port:user:pass 或 host:port:user-ip-1.2.3.4:pass")
		self.quick_btn = QPushButton("从串解析并填充")
		form = QFormLayout()
		form.addRow("Tag", self.tag)
		form.addRow("Protocol", self.protocol)
		form.addRow("出站JSON", self.body)
		form.addRow("快速串", self.quick_line)
		form.addRow(" ", self.quick_btn)
		btns = QHBoxLayout()
		btns.addWidget(self.refresh_btn)
		btns.addWidget(self.add_btn)
		btns.addWidget(self.update_btn)
		btns.addWidget(self.delete_btn)
		layout = QVBoxLayout(self)
		layout.addWidget(self.out)
		layout.addLayout(form)
		layout.addLayout(btns)

class RoutingPane(QWidget):
	def __init__(self) -> None:
		super().__init__()
		self.out = QTextEdit(); self.out.setReadOnly(True)
		self.routing = QTextEdit("")
		self.routing.setPlaceholderText('完整路由JSON，如 {"domainStrategy":"AsIs","rules":[...]}')
		self.rule = QTextEdit("")
		self.rule.setPlaceholderText('单条规则JSON，如 {"type":"field","outboundTag":"DIRECT"}')
		self.rule_index = QSpinBox(); self.rule_index.setRange(0, 100000)
		self.get_btn = QPushButton("获取路由")
		self.update_btn = QPushButton("更新路由")
		self.add_rule_btn = QPushButton("新增规则")
		self.del_rule_btn = QPushButton("删除规则")
		self.upd_rule_btn = QPushButton("更新规则")
		form = QFormLayout()
		form.addRow("当前路由", self.out)
		form.addRow("路由JSON", self.routing)
		form.addRow("规则JSON", self.rule)
		form.addRow("规则Index", self.rule_index)
		btns = QHBoxLayout()
		btns.addWidget(self.get_btn)
		btns.addWidget(self.update_btn)
		btns.addWidget(self.add_rule_btn)
		btns.addWidget(self.del_rule_btn)
		btns.addWidget(self.upd_rule_btn)
		layout = QVBoxLayout(self)
		layout.addLayout(form)
		layout.addLayout(btns)

class LogPane(QWidget):
	def __init__(self) -> None:
		super().__init__()
		self.out = QTextEdit(); self.out.setReadOnly(True)
		self.export_btn = QPushButton("导出日志")
		layout = QVBoxLayout(self)
		layout.addWidget(self.out)
		layout.addWidget(self.export_btn)

class MainWindow(QWidget):
	def __init__(self) -> None:
		super().__init__()
		self.setWindowTitle("3X-UI 增强API 桌面客户端")
		self.tabs = QTabWidget()
		self.login_pane = LoginPane()
		self.inbound_pane = InboundPane()
		self.monitor_pane = MonitorPane()
		self.outbound_pane = OutboundPane()
		self.routing_pane = RoutingPane()
		self.log_pane = LogPane()
		self.tabs.addTab(self.login_pane, "连接")
		self.tabs.addTab(self.inbound_pane, "入站管理")
		self.tabs.addTab(self.outbound_pane, "出站管理")
		self.tabs.addTab(self.routing_pane, "路由管理")
		self.tabs.addTab(self.monitor_pane, "监控")
		self.tabs.addTab(self.log_pane, "日志")
		layout = QVBoxLayout(self)
		layout.addWidget(self.tabs)
		self.xui: XUIClient | None = None
		self.enh: EnhancedAPIClient | None = None
		self.settings = QSettings("WCOJBK", "xui-enhanced-qt")
		# wiring
		self.login_pane.btn.clicked.connect(self.do_login)
		self.inbound_pane.list_btn.clicked.connect(self.list_inbounds)
		self.inbound_pane.create_btn.clicked.connect(self.create_vless_reality)
		self.inbound_pane.gen_btn.clicked.connect(self.gen_reality_keys)
		self.inbound_pane.server_gen_btn.clicked.connect(self.server_gen_reality_keys)
		self.inbound_pane.template_btn.clicked.connect(self.use_template_keys)
		self.inbound_pane.manual_btn.clicked.connect(self.manual_input_keys)
		self.inbound_pane.debug_btn.clicked.connect(self.debug_xray_environment)
		self.inbound_pane.copy_btn.clicked.connect(self.copy_vless_link)
		self.inbound_pane.refresh_btn.clicked.connect(self.refresh_uuid_email)
		self.inbound_pane.verify_btn.clicked.connect(self.verify_latest_inbound)
		self.monitor_pane.refresh.clicked.connect(self.refresh_monitor)
		self.log_pane.export_btn.clicked.connect(self.export_logs)
		# 出站管理 wiring
		self.outbound_pane.refresh_btn.clicked.connect(self.refresh_outbounds)
		self.outbound_pane.add_btn.clicked.connect(self.add_outbound)
		self.outbound_pane.update_btn.clicked.connect(self.update_outbound)
		self.outbound_pane.delete_btn.clicked.connect(self.delete_outbound)
		self.outbound_pane.quick_btn.clicked.connect(self.parse_and_fill_outbound)
		# 路由管理 wiring
		self.routing_pane.get_btn.clicked.connect(self.refresh_routing)
		self.routing_pane.update_btn.clicked.connect(self.update_routing)
		self.routing_pane.add_rule_btn.clicked.connect(self.add_route_rule)
		self.routing_pane.del_rule_btn.clicked.connect(self.delete_route_rule)
		self.routing_pane.upd_rule_btn.clicked.connect(self.update_route_rule)
		# load settings
		self.load_settings()

	def log(self, msg: str) -> None:
		self.log_pane.out.append(msg)

	def load_settings(self) -> None:
		xui = self.settings.value("xui_base", "http://127.0.0.1:2053")
		enh = self.settings.value("enh_base", "http://127.0.0.1:8080")
		user = self.settings.value("user", "admin")
		pwd = self.settings.value("pass", "")
		remember = self.settings.value("remember", True, type=bool)
		self.login_pane.xui_url.setText(xui)
		self.login_pane.enh_url.setText(enh)
		self.login_pane.user.setText(user)
		if pwd:
			self.login_pane.passwd.setText(pwd)
		self.login_pane.remember.setChecked(remember)
		self.log("已加载保存的连接配置")

	def save_settings(self) -> None:
		if not self.login_pane.remember.isChecked():
			return
		self.settings.setValue("xui_base", self.login_pane.xui_url.text().strip())
		self.settings.setValue("enh_base", self.login_pane.enh_url.text().strip())
		self.settings.setValue("user", self.login_pane.user.text().strip())
		self.settings.setValue("pass", self.login_pane.passwd.text())
		self.settings.setValue("remember", True)
		self.log("已保存登录信息")

	def do_login(self) -> None:
		xui_base = self.login_pane.xui_url.text().strip()
		enh_base = self.login_pane.enh_url.text().strip()
		user = self.login_pane.user.text().strip()
		pwd = self.login_pane.passwd.text().strip()
		# 传递增强API地址给XUIClient，用于出站和路由管理
		self.xui = XUIClient(xui_base, enhanced_api_url=enh_base)
		ok = self.xui.login(user, pwd)
		if ok:
			self.enh = EnhancedAPIClient(enh_base)
			self.login_pane.status.setText("登录成功")
			self.log(f"登录成功: {xui_base}")
			self.save_settings()
		else:
			self.login_pane.status.setText("登录失败")
			self.log("登录失败，请检查账号/地址")

	def list_inbounds(self) -> None:
		if not self.xui:
			QMessageBox.warning(self, "提示", "请先登录")
			return
		data = self.xui.list_inbounds()
		self.inbound_pane.out.setPlainText(str(data))
		self.log("已查询入站列表")

	def gen_reality_keys(self) -> None:
		if not _HAS_CRYPTO:
			QMessageBox.warning(self, "提示", "缺少 cryptography 依赖，先执行: pip install cryptography")
			self.log("生成密钥失败: 缺少 cryptography 依赖")
			return
		try:
			# 方法1：使用标准X25519密钥生成
			priv_obj = x25519.X25519PrivateKey.generate()
			pub_obj = priv_obj.public_key()
			
			# 获取原始32字节
			priv_bytes = priv_obj.private_bytes(
				encoding=serialization.Encoding.Raw,
				format=serialization.PrivateFormat.Raw,
				encryption_algorithm=serialization.NoEncryption(),
			)
			pub_bytes = pub_obj.public_bytes(
				encoding=serialization.Encoding.Raw,
				format=serialization.PublicFormat.Raw,
			)
			
			# 验证长度（X25519密钥必须是32字节）
			if len(priv_bytes) != 32 or len(pub_bytes) != 32:
				raise ValueError(f"密钥长度错误: 私钥{len(priv_bytes)}字节, 公钥{len(pub_bytes)}字节")
			
			# 转换为base64格式（与手动创建的格式一致）
			import base64
			priv_b64 = base64.b64encode(priv_bytes).decode('ascii')
			pub_b64 = base64.b64encode(pub_bytes).decode('ascii')
			
			# 填入界面
			self.inbound_pane.priv.setText(priv_b64)
			self.inbound_pane.pub_out.setText(pub_b64)
			
			self.log(f"✅ 已生成Reality密钥对(Base64格式)")
			self.log(f"🔑 私钥: {priv_b64[:16]}...{priv_b64[-16:]} (长度:{len(priv_b64)})")
			self.log(f"🗝️  公钥: {pub_b64[:16]}...{pub_b64[-16:]} (长度:{len(pub_b64)})")
			
		except Exception as e:
			QMessageBox.critical(self, "错误", f"生成密钥失败: {e}")
			self.log(f"❌ 生成密钥失败: {e}")
			# 调试信息
			self.log(f"🔧 调试: _HAS_CRYPTO={_HAS_CRYPTO}")
			import traceback
			self.log(f"🔧 详细错误: {traceback.format_exc()}")

	def copy_vless_link(self) -> None:
		host = self.inbound_pane.host.text().strip() or self.inbound_pane.sni.text().strip()
		port = int(self.inbound_pane.port.value())
		uuid_str = self.inbound_pane.uuid.text().strip()
		pub = self.inbound_pane.pub_out.text().strip()
		sni = self.inbound_pane.sni.text().strip()
		short_id = self.inbound_pane.short.text().strip()
		remark = f"vless-reality-{port}"
		if not (host and uuid_str and pub and sni and short_id):
			QMessageBox.warning(self, "提示", "请先生成密钥并填写必填项(主机/UUID/SNI/shortId)")
			self.log("复制失败: 信息不完整")
			return
		link = (
			f"vless://{uuid_str}@{host}:{port}?type=tcp&security=reality&flow=xtls-rprx-vision"
			f"&encryption=none&pbk={pub}&sni={sni}&fp=chrome&sid={short_id}#{remark}"
		)
		QApplication.clipboard().setText(link)
		self.log(f"已复制VLESS链接到剪贴板: {link}")

	def create_vless_reality(self) -> None:
		if not self.xui:
			QMessageBox.warning(self, "提示", "请先登录")
			return
		port = int(self.inbound_pane.port.value())
		uuid_str = self.inbound_pane.uuid.text().strip() or gen_uuid()
		sni = self.inbound_pane.sni.text().strip()
		short_id = self.inbound_pane.short.text().strip() or gen_short()
		priv = self.inbound_pane.priv.text().strip()
		email = self.inbound_pane.email.text().strip() or "reality@example.com"
		
		# 新增: 获取流量控制和到期时间
		total_gb = int(self.inbound_pane.total_gb.value())
		expiry_days = int(self.inbound_pane.expiry_days.value())
		limit_ip = int(self.inbound_pane.limit_ip.value())
		
		# 计算到期时间戳（毫秒）
		expiry_time = 0
		if expiry_days > 0:
			import time
			expiry_time = int((time.time() + expiry_days * 24 * 3600) * 1000)
		
		# 检查私钥和公钥
		pub = self.inbound_pane.pub_out.text().strip()
		
		if not priv:
			QMessageBox.warning(self, "提示", "请填写Reality私钥 (可点击'生成 Reality 密钥对'按钮)")
			self.log("创建失败: 未填写私钥")
			return
			
		if not pub:
			# 如果没有公钥，尝试从私钥计算
			if _HAS_CRYPTO:
				try:
					import base64
					# 尝试base64解码
					try:
						priv_bytes = base64.b64decode(priv)
					except:
						# 如果base64失败，尝试hex解码
						priv_bytes = bytes.fromhex(priv)
					
					priv_obj = x25519.X25519PrivateKey.from_private_bytes(priv_bytes)
					pub_obj = priv_obj.public_key()
					pub_bytes = pub_obj.public_bytes(
						encoding=serialization.Encoding.Raw,
						format=serialization.PublicFormat.Raw,
					)
					pub = base64.b64encode(pub_bytes).decode('ascii')
					self.inbound_pane.pub_out.setText(pub)
					self.log(f"🗝️  已从私钥计算公钥: {pub[:16]}...{pub[-16:]}")
				except Exception as e:
					QMessageBox.warning(self, "提示", f"私钥格式错误，请重新生成: {e}")
					self.log(f"私钥验证失败: {e}")
					return
			else:
				QMessageBox.warning(self, "提示", "请先点击'生成 Reality 密钥对'按钮生成完整密钥")
				self.log("创建失败: 缺少公钥且无法计算")
				return
		
		# 调试：记录发送的参数
		self.log(f"🔧 发送参数: 端口={port}, SNI={sni}, UUID={uuid_str[:8]}..., shortId={short_id}")
		
		resp = self.xui.add_vless_reality(port, uuid_str, sni, priv, short_id, email, total_gb, expiry_time, limit_ip, pub)
		self.inbound_pane.out.setPlainText(str(resp))
		
		if resp.get("success"):
			self.log(f"✅ 创建成功: 端口{port}, SNI {sni}, 流量{total_gb}GB, 有效期{expiry_days}天")
			
			# 强制更新入站配置以包含公钥
			try:
				import json, base64
				inbound_id = resp.get("obj", {}).get("id")
				stream_settings = resp.get("obj", {}).get("streamSettings", "")
				
				if inbound_id and stream_settings and _HAS_CRYPTO:
					stream_obj = json.loads(stream_settings)
					reality_settings = stream_obj.get("realitySettings", {})
					returned_private_key = reality_settings.get("privateKey", "")
					
					if returned_private_key:
						# 从私钥计算公钥
						# 兼容标准/URL安全Base64与无填充
						priv_bytes = _b64_to_bytes_any(returned_private_key)
						priv_obj = x25519.X25519PrivateKey.from_private_bytes(priv_bytes)
						pub_obj = priv_obj.public_key()
						pub_bytes = pub_obj.public_bytes(
							encoding=serialization.Encoding.Raw,
							format=serialization.PublicFormat.Raw,
						)
						pub_b64 = base64.b64encode(pub_bytes).decode('ascii')
						
						# 更新公钥显示
						self.inbound_pane.pub_out.setText(pub_b64)
						self.log(f"🗝️  已计算公钥: {pub_b64[:16]}...{pub_b64[-16:]}")
						
						# 强制更新入站配置，添加公钥到realitySettings
						reality_settings["publicKey"] = pub_b64
						stream_obj["realitySettings"] = reality_settings
						
						# 获取完整的入站配置进行更新
						settings_obj = json.loads(resp.get("obj", {}).get("settings", "{}"))
						sniffing_obj = json.loads(resp.get("obj", {}).get("sniffing", "{}"))
						allocate_obj = {"concurrency": 3, "refresh": 5, "strategy": "always"}
						
						update_payload = {
							"remark": f"vless-reality-{port}",
							"enable": True,
							"expiryTime": expiry_time,
							"listen": "",
							"port": port,
							"protocol": "vless",
							"settings": json.dumps(settings_obj),
							"streamSettings": json.dumps(stream_obj),  # 包含公钥的配置
							"sniffing": json.dumps(sniffing_obj),
							"allocate": json.dumps(allocate_obj),
						}
						
						# 更新入站
						update_resp = self.xui.update_inbound(inbound_id, update_payload)
						if update_resp.get("success"):
							self.log(f"✅ 已更新入站配置，公钥已添加到面板")
						else:
							self.log(f"⚠️  更新入站失败: {update_resp.get('msg', '未知错误')}")
							
				self.log(f"📋 StreamSettings: {stream_settings}")
			except Exception as e:
				self.log(f"⚠️  处理入站配置失败: {e}")
				import traceback
				self.log(f"🔧 详细错误: {traceback.format_exc()}")
		else:
			self.log(f"❌ 创建失败: {resp.get('msg', '未知错误')}")

	def refresh_monitor(self) -> None:
		if not self.enh:
			QMessageBox.information(self, "提示", "未配置增强API或未登录")
			self.log("刷新监控失败: 未配置增强API")
			return
		try:
			health = self.enh.health()
			stats = self.enh.traffic_summary("week")
			self.monitor_pane.out.setPlainText(f"Health:\n{health}\n\nStats(week):\n{stats}")
			self.log("已刷新监控信息")
		except Exception as e:
			self.monitor_pane.out.setPlainText(f"获取失败: {e}")
			self.log(f"刷新监控失败: {e}")

	def refresh_uuid_email(self) -> None:
		"""刷新UUID和Email避免重复冲突"""
		new_uuid = gen_uuid()
		new_email = f"reality_{secrets.randbelow(999999)}@example.com"
		new_short = gen_short()
		self.inbound_pane.uuid.setText(new_uuid)
		self.inbound_pane.email.setText(new_email)
		self.inbound_pane.short.setText(new_short)
		self.log(f"已刷新: UUID={new_uuid[:8]}..., Email={new_email}, shortId={new_short}")

	def verify_latest_inbound(self) -> None:
		"""验证最新创建的入站配置"""
		if not self.xui:
			QMessageBox.warning(self, "提示", "请先登录")
			return
		
		try:
			# 获取所有入站
			data = self.xui.list_inbounds()
			if not data or not isinstance(data, list):
				self.log("❌ 无法获取入站列表")
				return
			
			# 找到最新的入站（ID最大的）
			latest_inbound = max(data, key=lambda x: x.get('id', 0))
			inbound_id = latest_inbound.get('id')
			port = latest_inbound.get('port')
			stream_settings = latest_inbound.get('streamSettings', '')
			
			self.log(f"🔍 最新入站: ID={inbound_id}, 端口={port}")
			self.log(f"📋 实际StreamSettings: {stream_settings}")
			
			# 解析streamSettings检查dest
			import json
			try:
				stream_obj = json.loads(stream_settings) if isinstance(stream_settings, str) else stream_settings
				reality_settings = stream_obj.get('realitySettings', {})
				dest = reality_settings.get('dest', 'N/A')
				server_names = reality_settings.get('serverNames', [])
				self.log(f"📍 Target(dest): {dest}")
				self.log(f"📍 ServerNames: {server_names}")
			except Exception as e:
				self.log(f"❌ 解析StreamSettings失败: {e}")
				
		except Exception as e:
			self.log(f"❌ 验证失败: {e}")

	def server_gen_reality_keys(self) -> None:
		"""通过增强API在服务器上生成Reality密钥"""
		if not self.enh:
			QMessageBox.warning(self, "提示", "请先连接增强API")
			self.log("服务器生成密钥失败: 未连接增强API")
			return
		
		try:
			# 先检查服务器xray信息
			self.log("🔍 检查服务器xray环境...")
			xray_info = self.enh.get_xray_info()
			if xray_info.get("success"):
				info_data = xray_info.get("data", {})
				found_paths = info_data.get("foundPaths") or []
				version = info_data.get("version", "未知")
				can_generate = info_data.get("canGenerate", False)
				
				self.log(f"📋 服务器xray信息:")
				self.log(f"   路径: {found_paths}")
				self.log(f"   版本: {version}")
				self.log(f"   可生成: {can_generate}")
				
				if not can_generate:
					self.log("❌ 服务器无xray环境，回退到本地生成")
					self.gen_reality_keys()
					return
			
			# 调用服务器生成密钥
			self.log("🌐 正在调用服务器生成密钥...")
			resp = self.enh.generate_reality_keys()
			
			if resp.get("success"):
				keys = resp.get("data", {})
				private_key = keys.get("privateKey", "")
				public_key = keys.get("publicKey", "")
				method = keys.get("method", "")
				command = keys.get("command", "")
				
				if private_key and public_key:
					self.inbound_pane.priv.setText(private_key)
					self.inbound_pane.pub_out.setText(public_key)
					self.log(f"✅ 服务器生成密钥成功")
					self.log(f"🔧 生成方法: {method}")
					self.log(f"🔧 执行命令: {command}")
					self.log(f"🔑 私钥: {private_key[:16]}...{private_key[-16:]} (长度:{len(private_key)})")
					self.log(f"🗝️  公钥: {public_key[:16]}...{public_key[-16:]} (长度:{len(public_key)})")
					
					# 验证密钥格式
					validation = self.enh.validate_keys(private_key, public_key)
					if validation.get("success"):
						self.log("✅ 密钥格式验证通过")
					else:
						self.log(f"⚠️  密钥格式验证失败: {validation.get('msg', '未知错误')}")
				else:
					self.log("❌ 服务器返回的密钥为空")
					self.log(f"🔧 调试信息: {resp}")
			else:
				error_msg = resp.get("msg", "未知错误")
				status_code = resp.get("status", 0)
				self.log(f"❌ 服务器生成密钥失败: {error_msg} (状态码:{status_code})")
				self.log(f"🔧 完整响应: {resp}")
				
				# 回退到本地生成
				self.log("🔄 回退到本地生成密钥")
				self.gen_reality_keys()
				
		except Exception as e:
			self.log(f"❌ 服务器生成密钥异常: {e}")
			import traceback
			self.log(f"🔧 详细错误: {traceback.format_exc()}")
			# 回退到本地生成
			self.log("🔄 回退到本地生成密钥")
			self.gen_reality_keys()

	def use_template_keys(self) -> None:
		"""使用已知有效的模板密钥（从手动创建的端口20297复制）"""
		# 从您手动创建成功的端口20297入站复制的有效密钥对
		template_private = "IBl5LgqxOQQAxKUYl3i6Le83IWlwfAtArjYXaEwftFk"
		
		if _HAS_CRYPTO:
			try:
				import base64
				
				# 修复base64 padding问题
				def fix_base64_padding(data: str) -> str:
					"""修复base64字符串的padding"""
					missing_padding = len(data) % 4
					if missing_padding:
						data += '=' * (4 - missing_padding)
					return data
				
				# 修复私钥的padding并解码
				fixed_private = fix_base64_padding(template_private)
				priv_bytes = base64.b64decode(fixed_private)
				
				# 验证私钥长度
				if len(priv_bytes) != 32:
					raise ValueError(f"私钥长度错误: {len(priv_bytes)}字节，期望32字节")
				
				# 从私钥计算公钥
				priv_obj = x25519.X25519PrivateKey.from_private_bytes(priv_bytes)
				pub_obj = priv_obj.public_key()
				pub_bytes = pub_obj.public_bytes(
					encoding=serialization.Encoding.Raw,
					format=serialization.PublicFormat.Raw,
				)
				template_public = base64.b64encode(pub_bytes).decode('ascii')
				
				# 填入界面
				self.inbound_pane.priv.setText(template_private)
				self.inbound_pane.pub_out.setText(template_public)
				
				self.log(f"✅ 已使用模板密钥（来自成功的端口20297）")
				self.log(f"🔑 私钥: {template_private[:16]}...{template_private[-16:]}")
				self.log(f"🗝️  公钥: {template_public[:16]}...{template_public[-16:]}")
				self.log(f"🔧 私钥长度验证: {len(priv_bytes)}字节")
				
			except Exception as e:
				self.log(f"❌ 模板密钥处理失败: {e}")
				# 回退到本地生成
				self.log("🔄 回退到本地生成新密钥")
				self.gen_reality_keys()
		else:
			# 直接使用已知的私钥，提示手动生成公钥
			self.inbound_pane.priv.setText(template_private)
			self.log(f"✅ 已使用模板私钥，需要手动计算公钥")
			QMessageBox.information(self, "提示", "已填入模板私钥，但无法计算公钥。请安装cryptography依赖或使用其他生成方式。")

	def manual_input_keys(self) -> None:
		"""手动输入已知的有效密钥对"""
		from PySide6.QtWidgets import QInputDialog
		
		# 提供已知有效的密钥对（从端口20297）
		known_pairs = [
			{
				"name": "端口20297模板密钥",
				"private": "IBl5LgqxOQQAxKUYl3i6Le83IWlwfAtArjYXaEwftFk",
				"public": "需要计算"
			}
		]
		
		# 让用户选择或输入
		options = ["手动输入私钥"] + [pair["name"] for pair in known_pairs]
		choice, ok = QInputDialog.getItem(self, "选择密钥来源", "请选择:", options, 0, False)
		
		if not ok:
			return
			
		if choice == "手动输入私钥":
			# 手动输入私钥
			private_key, ok1 = QInputDialog.getText(self, "输入私钥", "请输入Reality私钥 (Base64格式):")
			if not ok1 or not private_key.strip():
				return
				
			public_key, ok2 = QInputDialog.getText(self, "输入公钥", "请输入Reality公钥 (Base64格式):")
			if not ok2 or not public_key.strip():
				# 尝试从私钥计算公钥
				if _HAS_CRYPTO:
					try:
						import base64
						priv_bytes = base64.b64decode(private_key.strip())
						priv_obj = x25519.X25519PrivateKey.from_private_bytes(priv_bytes)
						pub_obj = priv_obj.public_key()
						pub_bytes = pub_obj.public_bytes(
							encoding=serialization.Encoding.Raw,
							format=serialization.PublicFormat.Raw,
						)
						public_key = base64.b64encode(pub_bytes).decode('ascii')
						self.log("🗝️  已从手动输入的私钥计算公钥")
					except Exception as e:
						self.log(f"❌ 从私钥计算公钥失败: {e}")
						return
				else:
					self.log("❌ 无法计算公钥，请手动输入")
					return
			
			self.inbound_pane.priv.setText(private_key.strip())
			self.inbound_pane.pub_out.setText(public_key.strip())
			self.log(f"✅ 已手动填入密钥对")
			
		else:
			# 使用预设的模板
			for pair in known_pairs:
				if pair["name"] == choice:
					self.inbound_pane.priv.setText(pair["private"])
					self.log(f"✅ 已使用预设密钥: {choice}")
					
					# 尝试计算公钥
					if _HAS_CRYPTO:
						try:
							import base64
							priv_bytes = base64.b64decode(pair["private"])
							priv_obj = x25519.X25519PrivateKey.from_private_bytes(priv_bytes)
							pub_obj = priv_obj.public_key()
							pub_bytes = pub_obj.public_bytes(
								encoding=serialization.Encoding.Raw,
								format=serialization.PublicFormat.Raw,
							)
							public_key = base64.b64encode(pub_bytes).decode('ascii')
							self.inbound_pane.pub_out.setText(public_key)
							self.log(f"🗝️  已计算对应公钥")
						except Exception as e:
							self.log(f"❌ 计算公钥失败: {e}")
					break

	def debug_xray_environment(self) -> None:
		"""调试服务器xray环境"""
		if not self.enh:
			QMessageBox.warning(self, "提示", "请先连接增强API")
			return
		
		try:
			self.log("🔍 开始调试服务器xray环境...")
			
			# 调用强力搜索API
			resp = self.enh.session.get(f"{self.enh.base_url}/panel/api/enhanced/tools/find-xray")
			if resp.ok:
				data = resp.json()
				if data.get("success"):
					debug_data = data.get("data", {})
					# 兼容后端返回null的情况（Go中nil slice会被编码为null）
					all_paths = debug_data.get("allFoundPaths") or []
					valid_paths = debug_data.get("validPaths") or []
					
					self.log(f"📋 全面搜索结果:")
					self.log(f"   找到的所有xray文件: {len(all_paths)}个")
					for path in all_paths:
						self.log(f"     - {path}")
					
					self.log(f"📋 可用的xray路径: {len(valid_paths)}个")
					for path_info in valid_paths:
						path = path_info.get("path", "")
						version = path_info.get("version", "")
						accessible = path_info.get("accessible", False)
						self.log(f"     - {path} ({version}) - {'可用' if accessible else '不可用'}")
					
					if len(valid_paths) > 0:
						self.log("✅ 找到可用的xray，服务器应该能生成密钥")
					else:
						self.log("❌ 未找到可用的xray，建议手动安装")
				else:
					self.log(f"❌ 搜索失败: {data.get('msg', '未知错误')}")
			else:
				self.log(f"❌ 调用搜索API失败: {resp.status_code}")
				
		except Exception as e:
			self.log(f"❌ 调试异常: {e}")

	def export_logs(self) -> None:
		path, _ = QFileDialog.getSaveFileName(self, "导出日志", "xui-enhanced-log.txt", "Text Files (*.txt)")
		if not path:
			return
		with open(path, "w", encoding="utf-8") as f:
			f.write(self.log_pane.out.toPlainText())
		self.log(f"已导出日志到: {path}")

	# ---------------- 出站管理 ----------------
	def refresh_outbounds(self) -> None:
		if not self.xui:
			QMessageBox.warning(self, "提示", "请先登录")
			return
		resp = self.xui.list_outbounds()
		self.outbound_pane.out.setPlainText(str(resp))
		# 打印详细HTTP调试信息
		try:
			import json
			debug = self.xui.get_last_http_debug()
			self.log(f"[HTTP][刷新出站] {json.dumps(debug, ensure_ascii=False)}")
		except Exception:
			self.log("[HTTP][刷新出站] 无调试信息")
		self.log("已刷新出站列表")

	def add_outbound(self) -> None:
		if not self.xui:
			QMessageBox.warning(self, "提示", "请先登录")
			return
		try:
			import json
			tag = self.outbound_pane.tag.text().strip()
			protocol = self.outbound_pane.protocol.text().strip()
			body_txt = self.outbound_pane.body.toPlainText().strip()
			payload = {"tag": tag or gen_tag(), "protocol": protocol or "http"}
			if body_txt:
				try:
					body_obj = json.loads(body_txt)
					if isinstance(body_obj, dict):
						# 若已是完整出站对象，直接使用
						if "protocol" in body_obj and "settings" in body_obj:
							payload = body_obj
							if not payload.get("tag"):
								payload["tag"] = tag or gen_tag()
						else:
							payload.update(body_obj)
				except Exception:
					# 忽略解析失败，使用最小payload
					pass
			# 记录详细日志
			self.log(f"[新增出站][payload]={payload}")
			resp = self.xui.add_outbound(payload)
			self.log(str(resp))
			# 打印详细HTTP调试信息
			try:
				debug = self.xui.get_last_http_debug()
				self.log(f"[HTTP][新增出站] {json.dumps(debug, ensure_ascii=False)}")
			except Exception:
				self.log("[HTTP][新增出站] 无调试信息")
		except Exception as e:
			self.log(f"新增出站失败: {e}")

	def update_outbound(self) -> None:
		if not self.xui:
			QMessageBox.warning(self, "提示", "请先登录")
			return
		try:
			import json
			tag = self.outbound_pane.tag.text().strip()
			protocol = self.outbound_pane.protocol.text().strip()
			body_txt = self.outbound_pane.body.toPlainText().strip()
			payload = {"tag": tag or gen_tag(), "protocol": protocol or "http"}
			if body_txt:
				try:
					body_obj = json.loads(body_txt)
					if isinstance(body_obj, dict):
						if "protocol" in body_obj and "settings" in body_obj:
							payload = body_obj
							if not payload.get("tag"):
								payload["tag"] = tag or gen_tag()
						else:
							payload.update(body_obj)
				except Exception:
					pass
			self.log(f"[更新出站][tag]={tag} [payload]={payload}")
			resp = self.xui.update_outbound(tag or payload.get("tag"), payload)
			self.log(str(resp))
			try:
				debug = self.xui.get_last_http_debug()
				self.log(f"[HTTP][更新出站] {json.dumps(debug, ensure_ascii=False)}")
			except Exception:
				self.log("[HTTP][更新出站] 无调试信息")
		except Exception as e:
			self.log(f"更新出站失败: {e}")

	def delete_outbound(self) -> None:
		if not self.xui:
			QMessageBox.warning(self, "提示", "请先登录")
			return
		tag = self.outbound_pane.tag.text().strip()
		self.log(f"[删除出站][tag]={tag}")
		resp = self.xui.delete_outbound(tag)
		self.log(str(resp))
		try:
			import json
			debug = self.xui.get_last_http_debug()
			self.log(f"[HTTP][删除出站] {json.dumps(debug, ensure_ascii=False)}")
		except Exception:
			self.log("[HTTP][删除出站] 无调试信息")

	def parse_and_fill_outbound(self) -> None:
		"""解析格式 host:port:user:pass 或 host:port:user-ip-1.2.3.4:pass 填充为HTTP出站JSON"""
		line = self.outbound_pane.quick_line.text().strip()
		try:
			parts = line.split(":")
			if len(parts) != 4:
				QMessageBox.warning(self, "提示", "格式应为 host:port:user:pass 或 host:port:user-ip-1.2.3.4:pass")
				return
			host, port_str, user_part, password = parts
			# user 可能包含 -ip-xxx
			user = user_part
			protocol = "http"
			port = int(port_str)
			# 生成标准 Socks 出站
			import json
			ob = {
				"protocol": protocol,
				"tag": gen_tag("http-"),
				"settings": {
					"servers": [
						{
							"address": host,
							"port": port,
							"users": [ {"user": user, "pass": password} ]
						}
					]
				}
			}
			self.outbound_pane.tag.setText(ob["tag"])
			self.outbound_pane.protocol.setText(protocol)
			self.outbound_pane.body.setPlainText(json.dumps(ob, ensure_ascii=False, indent=2))
			self.log("已从快速串生成 HTTP 出站配置")
		except Exception as e:
			self.log(f"解析快速串失败: {e}")

	# ---------------- 路由管理 ----------------
	def refresh_routing(self) -> None:
		if not self.xui:
			QMessageBox.warning(self, "提示", "请先登录")
			return
		resp = self.xui.get_routing()
		self.routing_pane.out.setPlainText(str(resp))
		# 尝试把 data 渲染到可编辑框
		try:
			import json
			if isinstance(resp, dict) and resp.get("success"):
				self.routing_pane.routing.setPlainText(json.dumps(resp.get("obj") or resp.get("data"), ensure_ascii=False, indent=2))
		except Exception:
			pass
		self.log("已获取路由配置")

	def update_routing(self) -> None:
		if not self.xui:
			QMessageBox.warning(self, "提示", "请先登录")
			return
		try:
			import json
			routing_obj = json.loads(self.routing_pane.routing.toPlainText() or "{}")
			self.log(f"[更新路由][payload]={routing_obj}")
			resp = self.xui.update_routing(routing_obj)
			self.log(str(resp))
		except Exception as e:
			self.log(f"更新路由失败: {e}")

	def add_route_rule(self) -> None:
		if not self.xui:
			QMessageBox.warning(self, "提示", "请先登录")
			return
		try:
			import json
			rule_obj = json.loads(self.routing_pane.rule.toPlainText() or "{}")
			self.log(f"[新增规则][payload]={rule_obj}")
			resp = self.xui.add_route_rule(rule_obj)
			self.log(str(resp))
		except Exception as e:
			self.log(f"新增规则失败: {e}")

	def delete_route_rule(self) -> None:
		if not self.xui:
			QMessageBox.warning(self, "提示", "请先登录")
			return
		idx = int(self.routing_pane.rule_index.value())
		self.log(f"[删除规则][index]={idx}")
		resp = self.xui.delete_route_rule(idx)
		self.log(str(resp))

	def update_route_rule(self) -> None:
		if not self.xui:
			QMessageBox.warning(self, "提示", "请先登录")
			return
		try:
			import json
			idx = int(self.routing_pane.rule_index.value())
			rule_obj = json.loads(self.routing_pane.rule.toPlainText() or "{}")
			self.log(f"[更新规则][index]={idx} [payload]={rule_obj}")
			resp = self.xui.update_route_rule(idx, rule_obj)
			self.log(str(resp))
		except Exception as e:
			self.log(f"更新规则失败: {e}")

if __name__ == "__main__":
	app = QApplication(sys.argv)
	w = MainWindow()
	w.resize(960, 740)
	w.show()
	sys.exit(app.exec())
