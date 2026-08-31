import { PLVCallback, PLVChannelData, PLVJSONObject, PLVLiveSceneSDK, PLVUtils } from '@polyvharmony/live-scenes-sdk';
import { router, UIContext } from '@kit.ArkUI';
import { PLVLWWatchLayout, PLVWatchLayoutController } from '../components/PLVLWWatchLayout';
import { common } from '@kit.AbilityKit';
import { PLVLWPiPManager } from '../common/PLVLWPiPManager';

const TAG = '[PLVLWWatchPage]'
const ROUTE_NAME = 'PLVLWWatchPage'
let storage: LocalStorage = new LocalStorage()

export function pushToLiveWatchPage(sdkId: number, paramsCallback?: PLVCallback<PLVJSONObject>,
  uiContext?: UIContext) {
  const params: PLVJSONObject = {}
  params['sdkId'] = sdkId
  paramsCallback?.(params)
  storage = new LocalStorage()
  if (uiContext) {
    uiContext.getRouter().pushNamedRoute({
      name: ROUTE_NAME,
      params: params
    })
  } else {
    router.pushNamedRoute({
      name: ROUTE_NAME,
      params: params
    })
  }
}

@Entry({
  routeName: ROUTE_NAME,
  storage: storage
})
@Component
struct PLVLWWatchPage {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = PLVLiveSceneSDK.get((router.getParams() as PLVJSONObject)['sdkId'] as number)!
  @LocalStorageLink('channelData') channelData: PLVChannelData = this.sdk.channelData
  @State watchLayoutController: PLVWatchLayoutController = new PLVWatchLayoutController()
  private routeIndex: number = 0
  private routeName: string = ''
  private routePath: string = ''

  aboutToAppear(): void {
    // PiP 的 stateChange 回调运行在 PiP UI 容器中。必须保存主窗口页面的 UIContext，
    // 恢复时通过它的 Router 入栈，否则新页面会被创建到即将销毁的 PiP 容器。
    const mainUIContext = this.getUIContext()
    const routeState = mainUIContext.getRouter().getState()
    this.routeIndex = routeState.index
    this.routeName = routeState.name
    this.routePath = routeState.path
    PLVLWPiPManager.instance.bind(this.sdk, getContext() as common.UIAbilityContext, (sdkId: number) => {
      pushToLiveWatchPage(sdkId, undefined, mainUIContext)
    }, () => {
      mainUIContext.getRouter().back()
    })
    PLVUtils.setWindowFullScreen(true)
    PLVUtils.setWindowSystemBarProperties({ statusBarContentColor: "#FFFFFFFF" })
  }

  aboutToDisappear(): void {
    PLVUtils.setWindowFullScreen(false)
    PLVUtils.setWindowSystemBarProperties({ statusBarContentColor: "#FF000000" })
  }

  onPageShow(): void {
    PLVLWPiPManager.instance.restorePiPWhenSourcePageForeground()
  }

  onPageHide(): void {
    const routeState = this.getUIContext().getRouter().getState()
    const isSourcePageStillOnTop = routeState.index === this.routeIndex &&
      routeState.name === this.routeName && routeState.path === this.routePath
    if (isSourcePageStillOnTop) {
      // Home 键只会隐藏页面，不会改变 Router 栈；交给系统自动 PiP，继续受后台开关控制。
      return
    }
    // 路由切换时 onPageHide 早于 aboutToDisappear，此时 XComponent 仍在组件树上。
    // 目标页索引更大表示直播页被新页面覆盖，否则表示直播页被返回/替换移除。
    PLVLWPiPManager.instance.startPiPForPageDisappear(routeState.index > this.routeIndex)
  }

  override onBackPress(): boolean | void {
    if (this.watchLayoutController.onBackPressed()) {
      return true
    }
    if (PLVLWPiPManager.instance.startPiPForRoomExit()) {
      return true
    }
  }

  build() {
    Stack() {
      PLVLWWatchLayout({ layoutController: this.watchLayoutController }, storage)
    }
  }
}
