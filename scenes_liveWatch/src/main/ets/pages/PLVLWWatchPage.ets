import { PLVCallback, PLVChannelData, PLVJSONObject, PLVLiveSceneSDK, PLVUtils } from '@polyvharmony/live-scenes-sdk';
import { router } from '@kit.ArkUI';
import { PLVLWWatchLayout, PLVWatchLayoutController } from '../components/PLVLWWatchLayout';

const TAG = '[PLVLWWatchPage]'
const ROUTE_NAME = 'PLVLWWatchPage'
let storage: LocalStorage = new LocalStorage()

export function pushToLiveWatchPage(sdkId: number, paramsCallback?: PLVCallback<PLVJSONObject>) {
  const params: PLVJSONObject = {}
  params['sdkId'] = sdkId
  paramsCallback?.(params)
  storage = new LocalStorage()
  router.pushNamedRoute({
    name: ROUTE_NAME,
    params: params
  })
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

  aboutToAppear(): void {
    PLVUtils.setWindowFullScreen(true)
    PLVUtils.setWindowSystemBarProperties({ statusBarContentColor: "#FFFFFFFF" })
  }

  aboutToDisappear(): void {
    PLVUtils.setWindowFullScreen(false)
    PLVUtils.setWindowSystemBarProperties({ statusBarContentColor: "#FF000000" })
  }

  override onBackPress(): boolean | void {
    if (this.watchLayoutController.onBackPressed()) {
      return true
    }
  }

  build() {
    Stack() {
      PLVLWWatchLayout({ layoutController: this.watchLayoutController }, storage)
    }
  }
}