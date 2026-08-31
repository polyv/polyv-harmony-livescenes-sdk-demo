/**
 * 登录页与直播页 PiP 会话之间的轻量桥接。
 *
 * 此文件不能依赖 PLVLWPiPManager/XComponentController，否则登录页加载
 * scenes_liveWatch 模块时会在直播页面创建前提前初始化 UI 相关对象。
 */
export class PLVLWPiPEntranceBridge {
  static readonly instance: PLVLWPiPEntranceBridge = new PLVLWPiPEntranceBridge()

  private closeForNewSessionCallback?: () => Promise<void>

  bind(closeForNewSessionCallback: () => Promise<void>): void {
    this.closeForNewSessionCallback = closeForNewSessionCallback
  }

  unbind(): void {
    this.closeForNewSessionCallback = undefined
  }

  async closeForNewSession(): Promise<void> {
    await this.closeForNewSessionCallback?.()
  }
}
