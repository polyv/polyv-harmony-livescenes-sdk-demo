import {
  IPLVBackwardInterface,
  PLVBulletinEvent,
  PLVCallback,
  PLVChannelData,
  PLVCommonConstants,
  PLVDeviceUtils,
  PLVJSONUtils,
  PLVLiveSceneSDK,
  PLVLoginType,
  PLVRemoveBulletinEvent,
  PLVSocketOnEvent,
  PLVSocketStatus,
  PLVSocketStatusSup,
  PLVToastUtils,
  PLVUtils
} from '@polyvharmony/live-scenes-sdk'
import { router } from '@kit.ArkUI'
import { PLVDetailLayoutController, PLVLIDetailLayout } from '../components/PLVLIDetailLayout'
import { PLVLILiveHomeLayout, PLVLiveHomeLayoutController } from '../components/PLVLILiveHomeLayout'
import { PLVLIPlaybackHomeLayout, PLVPlaybackHomeLayoutController } from '../components/PLVLIPlaybackHomeLayout'
import { PLVLIPlayerLayout } from './player/PLVLIPlayerLayout'
import { common } from '@kit.AbilityKit'

const TAG = '[PLVLIWatchLayout]'

@Preview
@Component
export struct PLVLIWatchLayout {
  @Link layoutController: PLVWatchLayoutController
  @State bulletinSrc: string | undefined = ''
  @State liveHomeLayoutController: PLVLiveHomeLayoutController = new PLVLiveHomeLayoutController()
  @State playbackHomeLayoutController: PLVPlaybackHomeLayoutController = new PLVPlaybackHomeLayoutController()
  @State detailLayoutController: PLVDetailLayoutController = new PLVDetailLayoutController()
  @LocalStorageLink('sdk') sdk?: PLVLiveSceneSDK = undefined
  @LocalStorageLink('channelData') channelData?: PLVChannelData = undefined

  override aboutToAppear(): void {
    this.initData()
    this.onChatData()
    this.loginSocket()
  }

  override aboutToDisappear(): void {
    this.sdk?.destroy()
  }

  build() {
    Stack() {
      // player layout
      Stack() {
        PLVLIPlayerLayout()
      }
      .width(PLVCommonConstants.FULL_PERCENT)
      .height(PLVCommonConstants.FULL_PERCENT)
      .backgroundColor(Color.Gray)

      // tabs layout
      Tabs({ index: 1 }) {
        TabContent() {
          PLVLIDetailLayout({ layoutController: this.detailLayoutController, bulletinSrc: this.bulletinSrc })
        }

        TabContent() {
          if (PLVLoginType.LIVE == this.channelData?.loginType) {
            PLVLILiveHomeLayout({ layoutController: this.liveHomeLayoutController, bulletinSrc: this.bulletinSrc})
          } else {
            PLVLIPlaybackHomeLayout({ layoutController: this.playbackHomeLayoutController, bulletinSrc: this.bulletinSrc })
          }
        }

        TabContent() {
        }
      }
      .onChange((index) => {
        this.detailLayoutController.isLayoutShow = index == 0
      })
      .barHeight(0)
      .padding({ top: PLVDeviceUtils.getStatusBarHeight() })
      .width(PLVCommonConstants.FULL_PERCENT)
      .height(PLVCommonConstants.FULL_PERCENT)
      .hitTestBehavior(HitTestMode.Transparent)
      .gesture(SwipeGesture())

      // close widget
      Stack({ alignContent: Alignment.TopEnd }) {
        Image($r('app.media.plvli_close'))
          .width(48)
          .height(48)
          .padding(8)
          .margin({ right: 8 })
          .draggable(false)
          .onClick(() => {
            router.back()
          })
      }
      .padding({ top: PLVDeviceUtils.getStatusBarHeight() })
      .hitTestBehavior(HitTestMode.None)
      .width(PLVCommonConstants.FULL_PERCENT)
      .height(PLVCommonConstants.FULL_PERCENT)
    }
    .width(PLVCommonConstants.FULL_PERCENT)
    .height(PLVCommonConstants.FULL_PERCENT)
  }

  initData() {
    this.layoutController.detailLayoutController = this.detailLayoutController
    this.layoutController.liveHomeLayoutController = this.liveHomeLayoutController
    this.layoutController.playbackHomeLayoutController = this.playbackHomeLayoutController
    // 初始化sdk数据，如果当前模块为har类型，传getContext()；如果为hsp类型，则需要传getContext().createModuleContext('模块名')
    // 因sdk内部需要读取rawfile，因此这里需要传入模块的context
    this.sdk?.initData(getContext() as common.UIAbilityContext)
  }

  onChatData() {
    this.sdk?.chatroomManager.onData(PLVSocketOnEvent.MESSAGE, (data: string, event: string) => {
      switch (event) {
      // 公告
        case PLVBulletinEvent.EVENT:
          const bulletinEvent = PLVJSONUtils.json2Bean(PLVBulletinEvent, data)
          this.bulletinSrc = PLVUtils.undefinedToValue(bulletinEvent?.content, (value) => {
            this.bulletinSrc = value
          })
          break;
      // 移除公告
        case PLVRemoveBulletinEvent.EVENT:
          this.bulletinSrc = undefined
          break;
        default:
          break;
      }
    }, this)
    this.sdk?.chatroomManager.eventNotify.on('restrict_max_viewer', () => {
      PLVToastUtils.longShow($r('app.string.plvli_chat_restrict_max_viewer_hint'))
      router.back()
    }, this)
  }

  loginSocket() {
    this.sdk?.socketManager.onStatus((status: PLVSocketStatusSup) => {
      switch (status.socketStatus) {
        case PLVSocketStatus.LOGGING:
          PLVToastUtils.shortShow($r('app.string.plvli_chat_toast_logging'))
          break;
        case PLVSocketStatus.LOGIN_SUCCESS:
          PLVToastUtils.shortShow($r('app.string.plvli_chat_toast_login_success'))
          break;
        case PLVSocketStatus.RECONNECTING:
          PLVToastUtils.shortShow($r('app.string.plvli_chat_toast_reconnecting'))
          break;
        case PLVSocketStatus.RECONNECT_SUCCESS:
          PLVToastUtils.shortShow($r('app.string.plvli_chat_toast_reconnect_success'))
          break;
        case PLVSocketStatus.LOGIN_FAIL:
          getContext().resourceManager.getStringValue($r('app.string.plvli_chat_toast_login_failed'))
            .then((value) => {
              PLVToastUtils.shortShow(`${value}: message=${status.error?.message}`)
            })
          break;
        case PLVSocketStatus.BE_KICKED_OUT:
          PLVToastUtils.longShow($r('app.string.plvli_chat_toast_been_kicked'))
          router.back()
          break
        case PLVSocketStatus.LOGIN_REFUSE:
          this.showExitDialog($r('app.string.plvli_chat_toast_been_kicked'))
          break
        case PLVSocketStatus.LOGIN_ELSEWHERE:
          PLVToastUtils.longShow($r('app.string.plvli_chat_toast_account_login_elsewhere'))
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
      title: $r('app.string.plvli_common_dialog_tip_warm'),
      message: message,
      autoCancel: false,
      alignment: DialogAlignment.Center,
      onWillDismiss: () => {
      },
      confirm: {
        value: $r('app.string.plvli_common_dialog_confirm'),
        action: () => {
          router.back()
        }
      }
    })
  }
}

export class PLVWatchLayoutController implements IPLVBackwardInterface {
  detailLayoutController?: PLVDetailLayoutController
  liveHomeLayoutController?: PLVLiveHomeLayoutController
  playbackHomeLayoutController?: PLVPlaybackHomeLayoutController
  accessBackward: PLVCallback<void, boolean> = () => {
    return this.detailLayoutController?.accessBackward() || this.liveHomeLayoutController?.accessBackward() || this.playbackHomeLayoutController?.accessBackward() || false
  }
  backward: PLVCallback<void, void> = () => {
    if (this.detailLayoutController?.accessBackward()) {
      this.detailLayoutController.backward()
    } else if (this.liveHomeLayoutController?.accessBackward()) {
      this.liveHomeLayoutController.backward()
    } else if (this.playbackHomeLayoutController?.accessBackward()) {
      this.playbackHomeLayoutController.backward()
    }
  }
}