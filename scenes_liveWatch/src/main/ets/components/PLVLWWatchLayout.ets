import {
  PLVCallback,
  PLVCommonConstants,
  PLVLiveSceneSDK,
  PLVMediaQueryListener,
  PLVSocketStatus,
  PLVSocketStatusSup,
  PLVToastUtils,
  PLVUtils
} from '@polyvharmony/live-scenes-sdk';
import { lateInit } from '@polyvharmony/media-player-sdk';
import { PLVLWLayoutDataBus } from '../common/PLVLWLayoutDataBus';
import { PLVLWBottomLayerLayout } from './layer/PLVLWBottomLayerLayout';
import { PLVLWContentLayerLayout } from './layer/PLVLWContentLayerLayout';
import { PLVLWTopLayerLayout } from './layer/PLVLWTopLayerLayout';
import { common } from '@kit.AbilityKit';
import { router } from '@kit.ArkUI';
import { PLVLWDialogLayerLayout } from './layer/PLVLWDialogLayerLayout';

@Preview
@Component
export struct PLVLWWatchLayout {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @Provide('layoutDataBus') layoutDataBus: PLVLWLayoutDataBus = new PLVLWLayoutDataBus()
  @Link layoutController: PLVWatchLayoutController
  private orientationListener: PLVMediaQueryListener | undefined

  aboutToAppear(): void {
    this.initData()
    this.layoutDataBus.preload.preload(this.sdk)
    this.layoutDataBus.pptController.init(this.sdk)
    this.onChatData()
    this.loginSocket()
    this.layoutController.layoutDataBus = this.layoutDataBus
    this.orientationListener = PLVUtils.listenerOrientation((result) => {
      this.layoutDataBus.isPortrait.setValue(!result.matches)
    })
  }

  aboutToDisappear(): void {
    this.layoutDataBus.destroy()
    this.sdk.destroy()
    this.orientationListener?.off()
  }

  build() {
    Stack() {
      PLVLWBottomLayerLayout()
      PLVLWContentLayerLayout()
      PLVLWTopLayerLayout()
      PLVLWDialogLayerLayout()
    }
    .backgroundColor($r('app.color.plvlw_theme_bg_blue_merge_dark_70'))
    .width(PLVCommonConstants.FULL_PERCENT)
    .height(PLVCommonConstants.FULL_PERCENT)
  }

  initData() {
    // 初始化sdk数据，如果当前模块为har类型，传getContext()；如果为hsp类型，则需要传getContext().createModuleContext('模块名')
    // 因sdk内部需要读取rawfile，因此这里需要传入模块的context
    this.sdk.initData(getContext() as common.UIAbilityContext)
  }

  onChatData() {
    this.sdk?.chatroomManager.eventNotify.on('restrict_max_viewer', () => {
      PLVToastUtils.longShow($r('app.string.plvlw_chat_restrict_max_viewer_hint'))
      router.back()
    }, this)
  }

  loginSocket() {
    this.sdk?.socketManager.onStatus((status: PLVSocketStatusSup) => {
      switch (status.socketStatus) {
        case PLVSocketStatus.LOGGING:
          PLVToastUtils.shortShow($r('app.string.plvlw_chat_toast_logging'))
          break;
        case PLVSocketStatus.LOGIN_SUCCESS:
          PLVToastUtils.shortShow($r('app.string.plvlw_chat_toast_login_success'))
          break;
        case PLVSocketStatus.RECONNECTING:
          PLVToastUtils.shortShow($r('app.string.plvlw_chat_toast_reconnecting'))
          break;
        case PLVSocketStatus.RECONNECT_SUCCESS:
          PLVToastUtils.shortShow($r('app.string.plvlw_chat_toast_reconnect_success'))
          break;
        case PLVSocketStatus.LOGIN_FAIL:
          getContext().resourceManager.getStringValue($r('app.string.plvlw_chat_toast_login_failed'))
            .then((value) => {
              PLVToastUtils.shortShow(`${value}: message=${status.error?.message}`)
            })
          break;
        case PLVSocketStatus.BE_KICKED_OUT:
          PLVToastUtils.longShow($r('app.string.plvlw_chat_toast_been_kicked'))
          router.back()
          break
        case PLVSocketStatus.LOGIN_REFUSE:
          this.showExitDialog($r('app.string.plvlw_chat_toast_been_kicked'))
          break
        case PLVSocketStatus.LOGIN_ELSEWHERE:
          PLVToastUtils.longShow($r('app.string.plvlw_chat_toast_account_login_elsewhere'))
          setTimeout(() => {
            router.back()
          }, 3000)
          break
        default:
          break;
      }
    }, this)
    this.sdk?.socketManager.login()
  }

  showExitDialog(message: Resource) {
    AlertDialog.show({
      title: $r('app.string.plvlw_common_dialog_tip_warm'),
      message: message,
      autoCancel: false,
      alignment: DialogAlignment.Center,
      onWillDismiss: () => {
      },
      confirm: {
        value: $r('app.string.plvlw_common_dialog_confirm'),
        action: () => {
          router.back()
        }
      }
    })
  }
}

export class PLVWatchLayoutController {
  layoutDataBus?: PLVLWLayoutDataBus
  onBackPressed: PLVCallback<void, boolean | undefined> = () => {
    return this.layoutDataBus?.onBackPressed()
  }
}