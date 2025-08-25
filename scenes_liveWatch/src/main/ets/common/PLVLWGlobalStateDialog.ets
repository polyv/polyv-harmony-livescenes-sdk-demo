import { PLVCallback, PLVCommonConstants, PLVLiveSceneSDK, PLVNodeControllerManager } from '@polyvharmony/live-scenes-sdk';
import { PLVLWLayoutDataBus } from './PLVLWLayoutDataBus';
import { DialogName, PLVLWCommonDef } from './PLVLWCommonDef';
import { lateInit } from '@polyvharmony/media-player-sdk';

/**
 * 全局状态保留能力弹窗组件
 */
@Component
export struct PLVLWGlobalStateDialog {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @Consume('layoutDataBus') layoutDataBus: PLVLWLayoutDataBus
  private backHandler?: PLVCallback<void, boolean>
  @Prop dialogName: DialogName = 'default'
  @State backPriority: number = PLVLWCommonDef.BACK_PRIORITY_GLOBAL_DIALOG
  @State isShow: boolean = false

  aboutToAppear(): void {
    this.getNodeController().isShowPromise.observe((isShow) => {
      this.isShow = isShow
    })
    this.layoutDataBus?.registerBackPressedHandler(this.backHandler = () => {
      if (this.getNodeController().isShow) {
        this.getNodeController().show(false)
        return true
      }
      return false
    }, this.backPriority)
  }

  aboutToDisappear(): void {
    this.layoutDataBus.unregisterBackPressedHandler(this.backHandler)
  }

  build() {
    NodeContainer(this.getNodeController())
      .align(Alignment.BottomEnd)
      .onClick(() => {
        this.getNodeController().show(false)
      })
      .visibility(this.isShow ? Visibility.Visible : Visibility.None)
      .width(PLVCommonConstants.FULL_PERCENT)
      .height(PLVCommonConstants.FULL_PERCENT)
  }

  getNodeController() {
    return PLVNodeControllerManager.get(this.sdk.uniqueId).getOrCreate(this.dialogName)
  }
}

export function createDialog(config: DialogConfig) {
  PLVNodeControllerManager.get(config.uniqueId).getOrCreate({
    name: config.name,
    wrapBuilder: config.wrapBuilder,
    params: config.params
  })
}

export function showDialog(config: DialogConfig) {
  PLVNodeControllerManager.get(config.uniqueId).getOrCreate(config.name).show(config.isShow)
}

export function clearAllDialog(uniqueId: number) {
  PLVNodeControllerManager.delete(uniqueId)
}

interface DialogConfig {
  uniqueId: number
  name: DialogName
  wrapBuilder?: WrappedBuilder<[ESObject]>
  params?: ESObject
  isShow?: boolean
}