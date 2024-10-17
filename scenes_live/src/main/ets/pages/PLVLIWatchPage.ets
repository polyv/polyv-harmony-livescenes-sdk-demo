import { PLVCallback, PLVChannelData, PLVJSONObject, PLVLiveSceneSDK, PLVUtils } from '@polyvharmony/live-scenes-sdk';
import { PLVLIWatchLayout, PLVWatchLayoutController } from '../components/PLVLIWatchLayout';
import { router } from '@kit.ArkUI';
import { webview } from '@kit.ArkWeb';

const TAG = '[PLVLIWatchPage]'
const ROUTE_NAME = 'PLVLIWatchPage'
let storage: LocalStorage = new LocalStorage()

export function pushToWatchPage(sdkId: number, paramsCallback?: PLVCallback<PLVJSONObject>) {
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
struct PLVLIWatchPage {
  @LocalStorageLink('sdk') sdk?: PLVLiveSceneSDK = PLVLiveSceneSDK.get((router.getParams() as PLVJSONObject)['sdkId'] as number)
  @LocalStorageLink('channelData') channelData?: PLVChannelData = this.sdk?.channelData
  @State watchLayoutController: PLVWatchLayoutController = new PLVWatchLayoutController()

  aboutToAppear(): void {
    PLVUtils.setWindowFullScreen(true)
  }

  aboutToDisappear(): void {
    PLVUtils.setWindowFullScreen(false)
  }

  override onBackPress(): boolean | void {
    if (this.watchLayoutController.accessBackward()) {
      this.watchLayoutController.backward()
      return true
    }
  }

  build() {
    Stack() {
      PLVLIWatchLayout({ layoutController: this.watchLayoutController }, storage)
    }
  }
}