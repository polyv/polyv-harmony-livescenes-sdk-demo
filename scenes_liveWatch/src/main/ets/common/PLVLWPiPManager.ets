import { common } from '@kit.AbilityKit'
import { router } from '@kit.ArkUI'
import pipWindow from '@ohos.PiPWindow'
import { PLVLinkMicState, PLVLiveSceneSDK, PLVLoginType, PLVUtils } from '@polyvharmony/live-scenes-sdk'
import {
  MutableObserver,
  MutableState,
  PLVKVStore,
  PLVMediaOutputMode,
  PLVMediaPlayerPlayingState,
  Rect,
  watchStates
} from '@polyvharmony/media-player-sdk'
import { PLVLWPiPEntranceBridge } from './PLVLWPiPEntranceBridge'

// PLVLWPiPManager 在类定义时会立即创建静态单例，因此实例字段依赖的枚举
// 必须先完成初始化，不能声明在类后面。
enum PiPSourcePageState {
  KEEP,
  COVERED,
  REMOVED
}

/**
 * 直播观看页的画中画会话。
 *
 * 管理器独立于页面生命周期，页面通过 router 离开后仍可继续持有播放器；
 * 后续商品页等场景也可以直接调用 startPiPAndLeave() 触发小窗。
 */
export class PLVLWPiPManager {
  static readonly instance: PLVLWPiPManager = new PLVLWPiPManager()

  private readonly exitRoomAutoPiPEnabledStore: PLVKVStore<Boolean> =
    new PLVKVStore('plv_config_is_auto_floating_when_exit_page', Boolean)
  private readonly backgroundAutoPiPEnabledStore: PLVKVStore<Boolean> =
    new PLVKVStore('plv_config_is_auto_floating_when_go_home', Boolean)

  readonly xComponentController: XComponentController = new XComponentController()
  readonly isPiPActive: MutableState<boolean> = new MutableState(false)
  readonly isPiPStarting: MutableState<boolean> = new MutableState(false)
  /** 退出直播间或跳转其他页面时自动启用小窗，默认开启。 */
  readonly exitRoomAutoPiPEnabled: MutableState<boolean> = new MutableState(true)
  /** Home 键退至后台时自动启用小窗，默认开启，并受 exitRoomAutoPiPEnabled 控制。 */
  readonly backgroundAutoPiPEnabled: MutableState<boolean> = new MutableState(true)
  /** 当前播放状态是否满足进入小窗的业务条件。 */
  readonly canStartPiPState: MutableState<boolean> = new MutableState(false)
  /** “小窗播放”入口是否应显示。 */
  readonly canShowPiPAction: MutableState<boolean> = new MutableState(false)

  private sdk?: PLVLiveSceneSDK
  private controller?: pipWindow.PiPController
  private context?: common.UIAbilityContext
  private restorePage?: (sdkId: number) => void
  private restoreCoveredPage?: () => void
  private observers: MutableObserver[] = []
  private keepPlayerAlive: boolean = false
  private restoreRequested: boolean = false
  private restoringPlayerPending: boolean = false
  private autoPiPConfigLoaded: boolean = false
  private autoPiPConfigLoading: boolean = false
  private autoPiPConfigRevision: number = 0
  private sourcePageState: PiPSourcePageState = PiPSourcePageState.KEEP

  bind(sdk: PLVLiveSceneSDK, context: common.UIAbilityContext, restorePage: (sdkId: number) => void,
    restoreCoveredPage?: () => void): void {
    if (this.sdk?.uniqueId === sdk.uniqueId) {
      this.context = context
      this.restorePage = restorePage
      this.restoreCoveredPage = restoreCoveredPage
      return
    }
    MutableObserver.disposeAll(this.observers)
    this.observers = []
    this.sdk = sdk
    this.context = context
    this.restorePage = restorePage
    this.restoreCoveredPage = restoreCoveredPage
    PLVLWPiPEntranceBridge.instance.bind(() => this.stopPiPForNewSession())
    this.loadAutoPiPConfig()
    this.observePlayerState()
  }

  setExitRoomAutoPiPEnabled(enabled: boolean): void {
    this.autoPiPConfigRevision++
    this.exitRoomAutoPiPEnabled.setValue(enabled)
    this.updateBackgroundAutoStartEnabled()
    this.exitRoomAutoPiPEnabledStore.set(enabled).catch((error: Error) => {
      console.error(`[PLVLWPiPManager] save exit-room auto PiP config failed: ${error.message}`)
    })
  }

  setBackgroundAutoPiPEnabled(enabled: boolean): void {
    this.autoPiPConfigRevision++
    this.backgroundAutoPiPEnabled.setValue(enabled)
    this.updateBackgroundAutoStartEnabled()
    this.backgroundAutoPiPEnabledStore.set(enabled).catch((error: Error) => {
      console.error(`[PLVLWPiPManager] save background auto PiP config failed: ${error.message}`)
    })
  }

  private async loadAutoPiPConfig(): Promise<void> {
    if (this.autoPiPConfigLoaded || this.autoPiPConfigLoading) {
      return
    }
    this.autoPiPConfigLoading = true
    const revisionBeforeLoad = this.autoPiPConfigRevision
    try {
      const exitRoomEnabled = await this.exitRoomAutoPiPEnabledStore.get()
      const backgroundEnabled = await this.backgroundAutoPiPEnabledStore.get()
      // 读取期间用户可能已经操作开关，此时以最新操作为准，不能用旧存储值覆盖。
      if (revisionBeforeLoad === this.autoPiPConfigRevision) {
        this.exitRoomAutoPiPEnabled.setValue(exitRoomEnabled?.valueOf() ?? true)
        this.backgroundAutoPiPEnabled.setValue(backgroundEnabled?.valueOf() ?? true)
        this.updateBackgroundAutoStartEnabled()
      }
      this.autoPiPConfigLoaded = true
    } catch (error) {
      console.error(`[PLVLWPiPManager] load auto PiP config failed: ${JSON.stringify(error)}`)
    } finally {
      this.autoPiPConfigLoading = false
    }
  }

  /** XComponent 完成关联后预创建 controller，供 Home 键自动小窗使用。 */
  onXComponentReady(): void {
    this.ensureController()
      .then(() => this.updateBackgroundAutoStartEnabled())
      .catch((error: Error) => {
        console.error(`[PLVLWPiPManager] prepare PiP controller failed: ${error.message}`)
      })
  }

  shouldKeepPlayerAlive(sdkId: number): boolean {
    return this.sdk?.uniqueId === sdkId && this.keepPlayerAlive
  }

  consumeRestoringPlayer(sdkId: number): boolean {
    if (this.sdk?.uniqueId !== sdkId || !this.restoringPlayerPending) {
      return false
    }
    this.restoringPlayerPending = false
    // 恢复页的 XComponent 创建完成后，系统仍会经历 ABOUT_TO_STOP -> STOPPED，
    // 期间恢复页可能被临时触发 aboutToDisappear/onDestroy。此处只消费“播放器已迁回”
    // 标记，SDK 和播放器必须继续保活到 STOPPED，避免刚创建的新 SDK 被恢复页误销毁。
    return true
  }

  async startPiPAndLeave(): Promise<boolean> {
    if (!this.canStartPiP()) {
      return false
    }
    // 先退出 横屏 再进入 PiP
    if (PLVUtils.isLandscape()) {
      PLVUtils.changeOrientation(false)
    }
    return this.startPiP(PiPSourcePageState.REMOVED, true)
  }

  /** 返回键或其他主动退出直播间时调用，受“退出直播间自动启用小窗”控制。 */
  startPiPForRoomExit(): boolean {
    if (!this.exitRoomAutoPiPEnabled.value || !this.canStartPiP()) {
      return false
    }
    this.startPiP(PiPSourcePageState.REMOVED, true).then((started: boolean) => {
      // PiP 临时启动失败时仍完成用户原本的返回动作。
      if (!started) {
        router.back()
      }
    })
    return true
  }

  /**
   * Entry 页 onPageHide 时统一处理外部路由切换，不再要求每个 router.back 调用方单独适配。
   * @param isSourcePageCovered true 表示新页面入栈覆盖直播页；false 表示直播页已退出或被替换。
   */
  startPiPForPageDisappear(isSourcePageCovered: boolean = false): void {
    if (!this.exitRoomAutoPiPEnabled.value || !this.canStartPiP() ||
      this.isPiPStarting.value || this.isPiPActive.value) {
      return
    }
    this.startPiP(isSourcePageCovered ? PiPSourcePageState.COVERED : PiPSourcePageState.REMOVED, false)
  }

  /**
   * 原直播页重新显示时统一结束小窗：
   * 1. Home 键自动小窗后，从桌面点击 App 图标返回；
   * 2. 商品详情等页面覆盖直播页后，通过 router.back 返回。
   * 这两种路径都不会由系统主动触发 PiP 的 ABOUT_TO_RESTORE。
   */
  async restorePiPWhenSourcePageForeground(): Promise<void> {
    const isCoveredPageReturning = this.sourcePageState === PiPSourcePageState.COVERED
    const canRestoreSourcePage = this.sourcePageState === PiPSourcePageState.KEEP || isCoveredPageReturning
    if (!canRestoreSourcePage || this.restoreRequested ||
      (!this.isPiPActive.value && !this.isPiPStarting.value)) {
      return
    }
    const controller = this.controller
    if (!controller) {
      return
    }
    this.restoreRequested = true
    if (isCoveredPageReturning) {
      // 覆盖页面返回会重新创建直播页 XComponent，先标记为复用并重新挂载现有播放器。
      this.restoringPlayerPending = true
      this.keepPlayerAlive = true
    }
    try {
      await controller.stopPiP()
    } catch (error) {
      this.restoreRequested = false
      if (isCoveredPageReturning) {
        this.restoringPlayerPending = false
      }
      console.error(`[PLVLWPiPManager] restore PiP when source page foreground failed: ${JSON.stringify(error)}`)
    }
  }

  private async startPiP(sourcePageState: PiPSourcePageState, leavePage: boolean): Promise<boolean> {
    if (!this.sdk || !this.context || !pipWindow.isPiPEnabled() ||
      this.isPiPStarting.value || this.isPiPActive.value) {
      return false
    }
    this.isPiPStarting.setValue(true)
    this.keepPlayerAlive = true
    this.sourcePageState = sourcePageState
    try {
      const controller = await this.ensureController()
      if (!controller) {
        throw new Error('PiP controller is unavailable')
      }
      await controller.startPiP()
      if (leavePage) {
        router.back()
      }
      return true
    } catch (error) {
      console.error(`[PLVLWPiPManager] start PiP failed: ${JSON.stringify(error)}`)
      this.keepPlayerAlive = false
      this.isPiPStarting.setValue(false)
      this.sourcePageState = PiPSourcePageState.KEEP
      return false
    }
  }

  private async ensureController(): Promise<pipWindow.PiPController | undefined> {
    if (this.controller) {
      return this.controller
    }
    if (!this.sdk || !this.context || !pipWindow.isPiPEnabled()) {
      return undefined
    }
    const sdk = this.sdk
    const isLive = sdk.channelData.loginType === PLVLoginType.LIVE
    const videoSize = this.getVideoSize()
    const controller = await pipWindow.create({
      context: this.context,
      componentController: this.xComponentController,
      templateType: isLive
        ? pipWindow.PiPTemplateType.VIDEO_LIVE
        : pipWindow.PiPTemplateType.VIDEO_PLAY,
      contentWidth: videoSize.width,
      contentHeight: videoSize.height,
      controlGroups: isLive
        ? [pipWindow.VideoLiveControlGroup.VIDEO_PLAY_PAUSE]
        : []
    })
    // create 是异步的，会话可能已在等待期间被关闭或替换。
    // 旧 controller 不能在 clear 后重新注册到系统或覆盖新会话。
    if (this.sdk !== sdk) {
      this.disposeController(controller)
      return undefined
    }
    // 多个异步入口同时创建时，只保留最先完成并绑定到当前会话的 controller。
    if (!this.controller) {
      this.controller = controller
      this.observePiPEvents(controller)
    }
    this.updateBackgroundAutoStartEnabled()
    return this.controller
  }

  /**
   * 外部页面准备以新的登录会话进入观看页时，先结束当前 PiP 会话。
   * stopPiP 期间仍保留旧 SDK，直到系统完成小窗停止，再由 STOPPED 回调释放；
   * 如果 STOPPED 回调稍后才到，也会通过 controller 身份校验忽略，避免误伤新页面 SDK。
   */
  async stopPiPForNewSession(): Promise<void> {
    const controller = this.controller
    const oldSdk = this.sdk
    if (!controller || (!this.isPiPActive.value && !this.isPiPStarting.value)) {
      this.clear()
      oldSdk?.destroy()
      return
    }
    try {
      await controller.stopPiP()
      // stopPiP 的 Promise 可能先于最后一个 STOPPED 回调完成。返回登录页之前主动
      // 清掉旧会话，使随后到达的旧 controller 回调无法操作新绑定的 SDK。
      if (this.controller === controller) {
        this.keepPlayerAlive = false
        this.restoreRequested = false
        this.restoringPlayerPending = false
        this.isPiPActive.setValue(false)
        this.isPiPStarting.setValue(false)
        const shouldDestroyOldSdk = this.sdk?.uniqueId === oldSdk?.uniqueId
        this.clear()
        if (shouldDestroyOldSdk) {
          oldSdk?.destroy()
        }
      }
    } catch (error) {
      console.warn(`[PLVLWPiPManager] stop PiP for new session failed: ${JSON.stringify(error)}`)
    }
  }

  clearIfPlayerNotKept(sdkId: number): void {
    if (this.sdk?.uniqueId === sdkId && !this.keepPlayerAlive) {
      this.clear()
    }
  }

  private observePlayerState(): void {
    watchStates(() => {
      const player = this.sdk?.playerManager.mainMediaPlayer
      const videoSize = player?.getStateListenerRegistry().videoSize.value
      if (videoSize && videoSize.width() > 0 && videoSize.height() > 0) {
        this.controller?.updateContentSize(videoSize.width(), videoSize.height())
      }
      const isPlaying = player?.getStateListenerRegistry().playingState.value ===
        PLVMediaPlayerPlayingState.PLAYING
      this.controller?.updatePiPControlStatus(
        pipWindow.PiPControlType.VIDEO_PLAY_PAUSE,
        isPlaying ? pipWindow.PiPControlStatus.PLAY : pipWindow.PiPControlStatus.PAUSE
      )
      const canStart = this.computeCanStartPiP()
      this.canStartPiPState.setValue(canStart)
      this.canShowPiPAction.setValue(canStart && !this.isPiPActive.value && !this.isPiPStarting.value)
      this.updateBackgroundAutoStartEnabled(canStart)
    }).pushTo(this.observers)
  }

  private canStartPiP(): boolean {
    return this.canStartPiPState.value ?? false
  }

  private computeCanStartPiP(): boolean {
    if (!this.sdk) {
      return false
    }
    const fenestrulePlayEnabled = this.sdk.channelData.liveDetail?.isFenestrulePlayEnabled() ?? false
    const mediaPlayer = this.sdk.playerManager.mainMediaPlayer
    const linkmicState = this.sdk.linkmicManager.linkmicState.value
    const isLinkmic = linkmicState === PLVLinkMicState.Joined
    const isRequestingLinkmic = linkmicState === PLVLinkMicState.Requesting
    const mediaResource = mediaPlayer.getBusinessListenerRegistry().currentMediaResource.value
    const outputMode = mediaPlayer.getBusinessListenerRegistry().currentMediaOutputMode.value ??
      PLVMediaOutputMode.AUDIO_VIDEO
    const isMediaPlaying = mediaPlayer.getStateListenerRegistry().playingState.value ===
      PLVMediaPlayerPlayingState.PLAYING
    return fenestrulePlayEnabled && isMediaPlaying && !!mediaResource && !isLinkmic && !isRequestingLinkmic &&
      outputMode !== PLVMediaOutputMode.AUDIO_ONLY
  }

  private updateBackgroundAutoStartEnabled(canStart: boolean = this.canStartPiP()): void {
    const enabled = this.exitRoomAutoPiPEnabled.value && this.backgroundAutoPiPEnabled.value && canStart
    this.controller?.setAutoStartEnabled(enabled)
  }

  private observePiPEvents(controller: pipWindow.PiPController): void {
    controller.on('controlEvent', event => {
      if (this.controller !== controller) {
        return
      }
      if (event.controlType !== pipWindow.PiPControlType.VIDEO_PLAY_PAUSE || !this.sdk) {
        return
      }
      if (event.status === pipWindow.PiPControlStatus.PLAY) {
        if (this.sdk.channelData.loginType === PLVLoginType.LIVE) {
          this.sdk.playerManager.mainMediaPlayer.restart()
        } else {
          this.sdk.playerManager.mainMediaPlayer.start()
        }
      } else {
        this.sdk.playerManager.mainMediaPlayer.pause()
      }
    })
    controller.on('stateChange', (state: pipWindow.PiPState) => {
      // 已结束的旧 PiP controller 可能在新页面绑定后才派发尾部回调。
      // 只允许当前 controller 修改 SDK 和保活状态。
      if (this.controller !== controller) {
        return
      }
      if (state === pipWindow.PiPState.ABOUT_TO_START) {
        // 未经过 startPiP() 的 ABOUT_TO_START 来自 Home 键系统自动触发，原页面仍然保留。
        if (!this.isPiPStarting.value) {
          this.sourcePageState = PiPSourcePageState.KEEP
        }
        this.keepPlayerAlive = true
        this.isPiPStarting.setValue(true)
      } else if (state === pipWindow.PiPState.STARTED) {
        this.isPiPActive.setValue(true)
        this.isPiPStarting.setValue(false)
      } else if (state === pipWindow.PiPState.ABOUT_TO_RESTORE) {
        this.restoreRequested = true
        if (this.sourcePageState === PiPSourcePageState.REMOVED && this.sdk) {
          this.restoringPlayerPending = true
          const oldSdk = this.sdk
          const restoredSdk = PLVLiveSceneSDK.createByMigratingPlayer(oldSdk)
          this.sdk = restoredSdk
          // SDK 已切换为迁移后的新实例，重新订阅其连麦状态；播放器实例仍被无缝复用。
          MutableObserver.disposeAll(this.observers)
          this.observers = []
          this.observePlayerState()
          // 播放器已经迁出，可以在新页面创建前立即释放旧页面的 socket、Web、互动等模块，
          // 避免两套 SDK 的回调和网络连接在恢复过程中重叠。
          oldSdk.destroy()
          this.restorePage?.(restoredSdk.uniqueId)
        } else if (this.sourcePageState === PiPSourcePageState.COVERED) {
          // 商品详情等页面覆盖在直播页上，直接退回原页面，无需创建第二套 SDK。
          this.restoringPlayerPending = true
          this.restoreCoveredPage?.()
        }
      } else if (state === pipWindow.PiPState.STOPPED) {
        this.isPiPActive.setValue(false)
        this.isPiPStarting.setValue(false)
        if (!this.restoreRequested && this.sourcePageState === PiPSourcePageState.REMOVED) {
          const sdk = this.sdk
          this.clear()
          sdk?.destroy()
        } else {
          this.restoreRequested = false
          // 原页面仍存在，或正在恢复到新页面；结束临时保活但不能销毁当前 SDK。
          this.keepPlayerAlive = false
          this.sourcePageState = PiPSourcePageState.KEEP
        }
      } else if (state === pipWindow.PiPState.ERROR) {
        this.keepPlayerAlive = false
        this.isPiPActive.setValue(false)
        this.isPiPStarting.setValue(false)
      }
    })
  }

  private getVideoSize(): PiPVideoSize {
    const size: Rect | undefined = this.sdk?.playerManager.mainMediaPlayer
      .getStateListenerRegistry().videoSize.value
    if (size && size.width() > 0 && size.height() > 0) {
      return { width: size.width(), height: size.height() }
    }
    return { width: 16, height: 9 }
  }

  private clear(): void {
    MutableObserver.disposeAll(this.observers)
    this.observers = []
    const controller = this.controller
    // 先让旧回调失效，再注销系统侧的 Home 自动启动与监听。
    this.controller = undefined
    if (controller) {
      this.disposeController(controller)
    }
    this.sdk = undefined
    this.context = undefined
    this.restorePage = undefined
    this.restoreCoveredPage = undefined
    this.canStartPiPState.setValue(false)
    this.canShowPiPAction.setValue(false)
    this.keepPlayerAlive = false
    this.restoreRequested = false
    this.restoringPlayerPending = false
    this.isPiPActive.setValue(false)
    this.isPiPStarting.setValue(false)
    this.sourcePageState = PiPSourcePageState.KEEP
    PLVLWPiPEntranceBridge.instance.unbind()
  }

  private disposeController(controller: pipWindow.PiPController): void {
    // 仅清空 JS 引用不会取消系统持有的自动启动注册，Home 仍可能拉起已释放的小窗。
    try {
      controller.setAutoStartEnabled(false)
    } catch (error) {
      console.warn(`[PLVLWPiPManager] disable PiP auto start failed: ${JSON.stringify(error)}`)
    }
    try {
      controller.off('controlEvent')
    } catch (error) {
      console.warn(`[PLVLWPiPManager] unregister PiP control event failed: ${JSON.stringify(error)}`)
    }
    try {
      controller.off('stateChange')
    } catch (error) {
      console.warn(`[PLVLWPiPManager] unregister PiP state change failed: ${JSON.stringify(error)}`)
    }
  }
}

interface PiPVideoSize {
  width: number
  height: number
}
