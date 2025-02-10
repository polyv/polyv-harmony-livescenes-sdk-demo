import {
  PLVLinkMicCameraFacing,
  PLVLinkMicViewer,
  PLVLiveSceneSDK,
  PLVPushOrientation
} from '@polyvharmony/live-scenes-sdk';
import {
  MutableState,
  OnBackPressHandler,
  PLVKVStore,
  RecursivePartial,
  requireNotNull
} from '@polyvharmony/media-player-sdk';
import { PLVSALinkMicLayoutType } from '../components/linkmic/PLVSALinkMicLayout';
import { window } from '@kit.ArkUI';

export class PLVSAPageDataBus {
  /**
   * 当前直播界面阶段
   */
  readonly streamerStage = new MutableState(PLVSAStreamerStage.STARTUP)
  /**
   * 本地观看的连麦画面布局
   */
  readonly linkmicLayoutType = new MutableState(PLVSALinkMicLayoutType.TILE)
  /**
   * 连麦全屏显示的观众
   */
  readonly linkmicFullScreenViewer = new MutableState<PLVLinkMicViewer | null>(null)
  /**
   * 成员列表布局是否正在显示
   */
  readonly memberLayoutVisible = new MutableState(false)
  /**
   * 断网遮罩是否显示
   */
  readonly networkDisconnectedMaskVisible = new MutableState(false)
  /**
   * 是否竖屏
   */
  readonly isPortrait = new MutableState(true)
  /**
   * 返回回调
   */
  readonly onBackPressHandler = new OnBackPressHandler()
  /**
   * 保存直播的部分配置，用于直播中途异常退出时恢复为上次配置状态
   */
  readonly recoverSetting = new PLVSAStreamerRecoverSetting()

  finishStream(sdk: PLVLiveSceneSDK) {
    sdk.streamerManager.finishStream()
    sdk.linkmicManager.enableCamera(false)
    sdk.linkmicManager.enableMicrophone(false)
    this.streamerStage.setValue(PLVSAStreamerStage.END)
  }
}

export enum PLVSAStreamerStage {
  /**
   * 开始前准备阶段
   */
  STARTUP,
  /**
   * 直播中
   */
  LIVE,
  /**
   * 直播结束
   */
  END
}

export class PLVSAStreamerRecoverSetting {
  channelId?: string
  isPortrait?: boolean
  bitRateIndex?: number
  isEnableCamera?: boolean
  isFrontCamera?: boolean

  async recoverFromLocal(sdk: PLVLiveSceneSDK) {
    this.channelId = requireNotNull(sdk.channelData.loginChannelId)
    const setting = await this.kvStore.get()
    if (setting === undefined) {
      return
    }
    this.updateValue(setting)

    if (this.isPortrait !== undefined) {
      const windowInstance = await window.getLastWindow(getContext())
      windowInstance.setPreferredOrientation(this.isPortrait ? window.Orientation.PORTRAIT : window.Orientation.LANDSCAPE)
      sdk.streamerManager.setPushOrientation(this.isPortrait ? PLVPushOrientation.PORTRAIT : PLVPushOrientation.LANDSCAPE)
    }
    if (this.bitRateIndex !== undefined) {
      const targetBitRate = (sdk.streamerManager.channelSupportBitRateEncodeParams.value ?? [])
        .find(it => it.bitRate.index === this.bitRateIndex)
      if (targetBitRate !== undefined) {
        sdk.streamerManager.setBitRate(targetBitRate.bitRate)
      }
    }
    if (this.isEnableCamera !== undefined) {
      sdk.linkmicManager.enableCamera(this.isEnableCamera)
    }
    if (this.isFrontCamera !== undefined) {
      const currentFacingFront = sdk.linkmicManager.cameraFacing.value !== PLVLinkMicCameraFacing.BACK
      if (currentFacingFront !== this.isFrontCamera) {
        sdk.linkmicManager.switchCamera()
      }
    }
  }

  update(partial: RecursivePartial<PLVSAStreamerRecoverSetting>) {
    this.updateValue(partial)
    this.saveToLocal()
  }

  private updateValue(partial: RecursivePartial<PLVSAStreamerRecoverSetting>) {
    this.channelId = partial.channelId ?? this.channelId
    this.isPortrait = partial.isPortrait ?? this.isPortrait
    this.bitRateIndex = partial.bitRateIndex ?? this.bitRateIndex
    this.isEnableCamera = partial.isEnableCamera ?? this.isEnableCamera
    this.isFrontCamera = partial.isFrontCamera ?? this.isFrontCamera
  }

  private async saveToLocal() {
    if (this.channelId !== undefined) {
      await this.kvStore.set(this)
    }
  }

  private get kvStore() {
    return new PLVKVStore(`plvsa_streamer_recover_setting_${requireNotNull(this.channelId)}`, PLVSAStreamerRecoverSetting)
  }
}