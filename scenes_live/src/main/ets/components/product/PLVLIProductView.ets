import { PLVCommonConstants, PLVLiveSceneSDK, PLVProductDataBean, PLVTextUtils, PLVToastUtils } from '@polyvharmony/live-scenes-sdk'
import { pushToProductDetailPage } from './PLVLIProductDetailPage'
import { PLVProductWebViewController } from './PLVLIProductWebView'

const TAG = '[PLVLIProductView]'

@Preview
@Component
export struct PLVLIProductView {
  @LocalStorageLink('sdk') sdk?: PLVLiveSceneSDK = undefined
  @Link productDataBean: PLVProductDataBean
  @State clickTimesScale: number = 1
  @Link productWebViewController: PLVProductWebViewController

  build() {
    RelativeContainer() {
      this.pushCardView()
      Image($r('app.media.plvli_shopping_trolley'))
        .width(32)
        .height(32)
        .draggable(false)
        .alignRules({
          top: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Top },
          left: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.Start },
          bottom: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Bottom },
          right: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.End }
        })
        .onClick(() => {
          this.productWebViewController.isShow = true
        })
        .id('entryImageView')
    }
    .width(32)
    .height(32)
  }

  @Builder
  pushCardView() {
    if (this.productDataBean.pushContentBean &&
      !this.productDataBean.pushContentBean.isBigProduct()) {
      Column() {
        RelativeContainer() {
          if (this.productDataBean.pushContentBean.getCover()) {
            Image(this.productDataBean.pushContentBean.getCover())
              .draggable(false)
              .width(96)
              .alignRules({
                left: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.Start },
                top: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Top },
                bottom: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Bottom }
              })
              .borderRadius(4)
              .id('coverView')
          } else {
            Text(PLVTextUtils.toString(this.productDataBean.pushContentBean.showId))
              .width(96)
              .fontColor('#FFFFFFFF')
              .backgroundColor('#59000000')
              .fontSize(24)
              .alignRules({
                left: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.Start },
                top: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Top },
                bottom: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Bottom }
              })
              .borderRadius(4)
              .fontWeight(FontWeight.Bold)
              .textAlign(TextAlign.Center)
              .id('coverView')
          }
          if (this.productDataBean.hotEffectEnable) {
            Text() {
              ImageSpan($r('app.media.plvli_product_hot_effect_icon'))
                .width(10)
                .height(10)
                .margin({ right: 4 })
                .verticalAlign(ImageSpanAlignment.CENTER)
              Span(this.productDataBean.hotEffectTips)
                .fontColor('#FFFFFFFF')
                .fontSize(10)
              if (this.productDataBean.getHotEffectClickTimes()) {
                Span(` x${this.productDataBean.getHotEffectClickTimes()}`)
                  .fontColor('#FFFFFFFF')
                  .fontSize(10)
              }
            }
            .borderRadius({ topLeft: 4, topRight: 4 })
            .alignRules({
              top: { anchor: 'coverView', align: VerticalAlign.Top },
              left: { anchor: 'coverView', align: HorizontalAlign.Start },
              right: { anchor: 'coverView', align: HorizontalAlign.End }
            })
            .padding({ left: 4 })
            .height(20)
            .backgroundImage($r('app.media.plvli_greet_bg'))
            .backgroundImageSize(ImageSize.Cover)
          }
          Text(this.productDataBean.pushContentBean.name)
            .margin({ left: 8 })
            .alignRules({
              left: { anchor: 'coverView', align: HorizontalAlign.End },
              top: { anchor: 'coverView', align: VerticalAlign.Top },
              bottom: { anchor: 'featuresRow', align: VerticalAlign.Top },
              right: { anchor: 'closeImageView', align: HorizontalAlign.Start }
            })
            .fontSize(14)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .fontColor(Color.Gray)
            .chainMode(Axis.Vertical, ChainStyle.SPREAD_INSIDE)
            .id('nameTextView')
          if (this.productDataBean.pushContentBean.getParsedFeatures()) {
            Row() {
              ForEach(this.productDataBean.pushContentBean.getParsedFeatures(), (item: string, index) => {
                Text(item)
                  .fontSize(10)
                  .padding({
                    left: 6,
                    right: 6,
                    top: 2,
                    bottom: 2
                  })
                  .margin({ right: 6 })
                  .borderRadius(4)
                  .fontColor('#FF8F11')
                  .backgroundColor('#14FF8F11')
              })
            }
            .alignRules({
              top: { anchor: 'nameTextView', align: VerticalAlign.Bottom },
              left: { anchor: 'nameTextView', align: HorizontalAlign.Start },
              bottom: { anchor: 'descTextView', align: VerticalAlign.Top }
            })
            .id('featuresRow')
          }
          Text(this.productDataBean.pushContentBean.productDesc)
            .alignRules({
              left: { anchor: 'nameTextView', align: HorizontalAlign.Start },
              top: { anchor: 'featuresRow', align: VerticalAlign.Bottom },
              bottom: { anchor: 'priceTextView', align: VerticalAlign.Top },
              right: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.End }
            })
            .fontSize(12)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .fontColor('#99333333')
            .id('descTextView')
          Text() {
            if (this.productDataBean.pushContentBean.isNormalProduct()) {
              Span(this.productDataBean.pushContentBean.isFreeForPay() ? $r('app.string.plvli_commodity_free') : `¥${this.productDataBean.pushContentBean.realPrice}`)
                .fontColor('#FF473A')
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
              if (!(this.productDataBean.pushContentBean.isRealPriceEqualsPrice() || this.productDataBean.pushContentBean.isSrcPriceZero() ||
              this.productDataBean.pushContentBean.isFinanceProduct())) {
                Span(`  `)
                Span(`¥${this.productDataBean.pushContentBean.price}`)
                  .fontColor('#ADADC0')
                  .decoration({ type: TextDecorationType.LineThrough, color: '#ADADC0', style: TextDecorationStyle.SOLID })
                  .fontSize(12)
              }
            } else if (this.productDataBean.pushContentBean.isFinanceProduct()) {
              Span(this.productDataBean.pushContentBean.yield)
                .fontColor('#FF473A')
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
            } else if (this.productDataBean.pushContentBean.isPositionProduct()) {
              Span(this.productDataBean.pushContentBean.getTreatment())
                .fontColor('#FF473A')
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
            }
          }
          .alignRules({
            left: { anchor: 'nameTextView', align: HorizontalAlign.Start },
            top: { anchor: 'descTextView', align: VerticalAlign.Bottom },
            bottom: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Bottom },
            right: { anchor: 'linkEntryImageView', align: HorizontalAlign.Start }
          })
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .id('priceTextView')

          Image(this.getLink() ? $r('app.media.plvli_product_enter') : $r('app.media.plvli_product_enter_disabled'))
            .width(24)
            .height(24)
            .draggable(false)
            .objectFit(ImageFit.Contain)
            .margin({ right: 10 })
            .alignRules({
              right: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.End },
              bottom: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Bottom }
            })
            .id('linkEntryImageView')
          Image($r('app.media.plvli_product_push_close'))
            .draggable(false)
            .alignRules({
              right: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.End },
              top: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Top }
            })
            .onClick(() => {
              this.sdk?.productManager.notifyPush(undefined)
            })
            .objectFit(ImageFit.Contain)
            .padding(8)
            .translate({ x: 8, y: -8 })
            .width(24)
            .height(24)
            .id('closeImageView')
        }
        .onClick(() => {
          this.handlePushCardClick()
        })
        .padding(10)
        .borderRadius(8)
        .backgroundColor(Color.White)
        .translate({ x: 32 })
        .height(0)
        .layoutWeight(1)

        Polygon({ width: 16, height: 14 })
          .points([[0, 0], [8, 8], [16, 0]])
          .translate({ x: -8 })
          .fill(Color.White)
      }
      .width(300)
      .height(132)
      .translate({ y: -32 })
      .alignItems(HorizontalAlign.End)
      .justifyContent(FlexAlign.End)
      .alignRules({
        bottom: { anchor: 'entryImageView', align: VerticalAlign.Bottom },
        right: { anchor: 'entryImageView', align: HorizontalAlign.End }
      })
    }
  }

  handlePushCardClick() {
    const link = this.getLink()
    if (!link) {
      PLVToastUtils.longShow($r('app.string.plvli_commodity_toast_empty_link'))
      return
    }
    this.sdk?.productManager.notifyClick()
    this.sdk?.productManager.notifyPush(undefined)
    pushToProductDetailPage(link)
  }

  getLink(): string | undefined {
    return this.productDataBean.pushContentBean?.getLinkByType()
  }
}