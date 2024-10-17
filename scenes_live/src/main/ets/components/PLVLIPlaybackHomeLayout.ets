import { IPLVBackwardInterface, PLVCallback, PLVChannelData, PLVCommonConstants, PLVDeviceUtils, PLVLiveSceneSDK, PLVProductDataBean } from '@polyvharmony/live-scenes-sdk'
import { PLVLIChatPlaybackLayout } from './chatroom/PLVLIChatPlaybackLayout'
import { PLVLIToTopView } from './chatroom/PLVLIToTopView'
import { PLVLIBulletinView } from './liveroom/PLVLIBulletinView'
import { PLVLIMoreView } from './liveroom/PLVLIMoreView'
import { PLVLIWatchInfoView } from './liveroom/PLVLIWatchInfoView'
import { PLVLIProductView } from './product/PLVLIProductView'
import { PLVLIProductWebView, PLVProductWebViewController } from './product/PLVLIProductWebView'

const TAG = '[PLVLIPlaybackHomeLayout]'

@Preview
@Component
export struct PLVLIPlaybackHomeLayout {
  @LocalStorageLink('sdk') sdk?: PLVLiveSceneSDK = undefined
  @LocalStorageLink('channelData') channelData?: PLVChannelData = undefined
  @Link layoutController: PLVPlaybackHomeLayoutController
  @Link bulletinSrc: string | undefined
  @State productDataBean?: PLVProductDataBean = this.sdk?.productManager.getData()
  @State productWebViewController: PLVProductWebViewController = new PLVProductWebViewController()

  aboutToAppear(): void {
    this.initData()
    this.onProductData()
  }

  build() {
    RelativeContainer() {
      // <editor-fold defaultstate="collapsed" desc="观看信息View">
      PLVLIWatchInfoView()
        .alignRules({
          top: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Top },
          left: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.Start }
        })
        .margin({ left: 16 })
        .id('watchInfoView')
      // </editor-fold>
      // <editor-fold defaultstate="collapsed" desc="公告View">
      PLVLIBulletinView({ bulletinSrc: this.bulletinSrc })
        .alignRules({
          top: { anchor: 'watchInfoView', align: VerticalAlign.Bottom },
          left: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.Start }
        })
        .margin({ left: 16, top: 16, right: 16 })
        .id('bulletinView')
      // </editor-fold>
      // <editor-fold defaultstate="collapsed" desc="评论上墙View">
      PLVLIToTopView()
        .alignRules({
          top: { anchor: 'bulletinView', align: VerticalAlign.Bottom },
          middle: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.Center }
        })
        .margin({ top: 8 })
        .id('toTopView')
      // </editor-fold>
      // <editor-fold defaultstate="collapsed" desc="聊天回放Layout">
      PLVLIChatPlaybackLayout()
        .alignRules({
          bottom: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Bottom },
          left: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.Start }
        })
        .margin({ bottom: 128 })
        .id('chatListLayout')
      // </editor-fold>
      // <editor-fold defaultstate="collapsed" desc="商品View">
      Row() {
        if (this.productDataBean?.isOpenProduct) {
          PLVLIProductView({
            productDataBean: this.productDataBean,
            productWebViewController: this.productWebViewController
          })
            .margin({ right: 12 })
            .id('productView')
        }
      }
      .alignRules({
        right: { anchor: 'moreView', align: HorizontalAlign.Start },
        bottom: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Bottom }
      })
      .id('rightBottomRow')
      // </editor-fold>
      // <editor-fold defaultstate="collapsed" desc="更多View">
      PLVLIMoreView()
        .alignRules({
          right: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.End },
          bottom: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Bottom }
        })
        .margin({ right: 16 })
        .id('moreView')
      // </editor-fold>
      // <editor-fold defaultstate="collapsed" desc="商品WebView">
      PLVLIProductWebView({
        viewController: this.productWebViewController
      })
        .zIndex(99)
        .id('productWebView')
      // </editor-fold>
    }
    .padding({ top: 6, bottom: 6 + PLVDeviceUtils.getNavigationIndicatorHeight() })
    .width(PLVCommonConstants.FULL_PERCENT)
    .height(PLVCommonConstants.FULL_PERCENT)
  }

  initData() {
    this.layoutController.productWebViewController = this.productWebViewController
  }

  onProductData() {
    this.sdk?.productManager.eventNotify.on('product_data', (value: PLVProductDataBean) => {
      this.productDataBean = value
    }, this)
  }
}

export class PLVPlaybackHomeLayoutController implements IPLVBackwardInterface {
  productWebViewController?: PLVProductWebViewController
  accessBackward: PLVCallback<void, boolean> = () => {
    return this.productWebViewController?.accessBackward() || false
  }
  backward: PLVCallback<void, void> = () => {
    if (this.productWebViewController?.accessBackward()) {
      this.productWebViewController.backward()
    }
  }
}