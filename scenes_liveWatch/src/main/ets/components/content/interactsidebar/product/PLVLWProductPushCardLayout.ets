import { PLVCommonConstants, PLVLiveSceneSDK, PLVProductDataBean, PLVToastUtils } from '@polyvharmony/live-scenes-sdk';
import { lateInit, MutableObserver, mutableStateOf, State as PLVState } from '@polyvharmony/media-player-sdk';
import { pushToProductDetailPage } from '../../toolbar/product/PLVLWProductDetailPage';

@Component
export struct PLVLWProductPushCardLayout {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  private readonly productDataBeanState = mutableStateOf(this.sdk.productManager.getData())
  @State productDataBean: PLVProductDataBean = this.sdk.productManager.getData()
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    this.sdk.productManager.eventNotify.on('product_data', this.onProductData, this)
    this.productDataBeanState.observe(it => this.productDataBean = it).pushTo(this.observers)
  }

  private readonly onProductData = (value: PLVProductDataBean) => {
    this.productDataBeanState.value = value
  }

  build() {
    Stack() {
      if (this.productDataBean.isOpenProduct && this.productDataBean.pushContentBean && !this.productDataBean.pushContentBean.isBigProduct()) {
        if (this.productDataBean.pushContentBean.getCover()) {
          ImageProductCard({
            productDataBean: this.productDataBeanState,
            onClickProduct: this.onClickProduct,
            onCloseProduct: this.onCloseProduct
          })
        } else {
          NoImageProductCard({
            productDataBean: this.productDataBeanState,
            onClickProduct: this.onClickProduct,
            onCloseProduct: this.onCloseProduct
          })
        }
      }
    }
  }

  private readonly onClickProduct = () => {
    const productContent = this.productDataBean.pushContentBean
    if (!productContent) {
      return
    }
    if (productContent.isNormalProduct() && !productContent.isPriceOpened()) {
      return
    }
    const link = productContent.getLinkByType()
    if (!link) {
      PLVToastUtils.longShow($r('app.string.plvlw_commodity_toast_empty_link'))
      return
    }
    this.sdk.productManager.notifyClick()
    this.sdk.productManager.notifyPush(undefined)
    pushToProductDetailPage(link)
  }
  private readonly onCloseProduct = () => {
    this.sdk.productManager.notifyPush(undefined)
  }

  aboutToDisappear(): void {
    this.sdk.productManager.eventNotify.off('product_data', this.onProductData)
    MutableObserver.disposeAll(this.observers)
  }
}

@Component
struct ImageProductCard {
  productDataBean: PLVState<PLVProductDataBean> = lateInit()
  onClickProduct: () => void = lateInit()
  onCloseProduct: () => void = lateInit()
  @State private hotEffectEnable: boolean = false
  @State private hotEffectClickTimes: number = 0
  @State private hotEffectClickTimesText: string = ''
  @State private hotEffectIcon: Resource = $r('app.media.plvlw_product_push_hot_effect_icon_normal')
  @State private hotEffectText: ResourceStr = $r('app.string.plvlw_product_push_hot_effect_text_normal')
  @State private productIndex: string = ''
  @State private productCover: string = ''
  @State private productTag: string | undefined = undefined
  @State private productName: string = ''
  @State private productPrice: ResourceStr = ''
  @State private productPriceOpened: boolean = true
  @State private productBuyText: ResourceStr = $r('app.string.plvlw_commodity_buy')
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    this.productDataBean.observe(productDataBean => {
      const pushContentBean = productDataBean.pushContentBean
      this.productIndex = pushContentBean?.showId?.toString() ?? ''
      this.productCover = pushContentBean?.getCover() ?? ''
      this.productTag = pushContentBean?.getParsedFeatures()?.[0]
      this.productName = pushContentBean?.name ?? ''
      if (pushContentBean?.isNormalProduct()) {
        this.productPriceOpened = pushContentBean.isPriceOpened()
        if (!this.productPriceOpened) {
          this.productPrice = `¥??`
        } else if (pushContentBean.customPrice) {
          this.productPrice = pushContentBean.customPrice
        } else if (pushContentBean.isFreeForPay()) {
          this.productPrice = $r('app.string.plvlw_commodity_free')
        } else {
          this.productPrice = `¥${pushContentBean.realPrice}`
        }
        this.hotEffectIcon = $r('app.media.plvlw_product_push_hot_effect_icon_normal')
        this.hotEffectText = $r('app.string.plvlw_product_push_hot_effect_text_normal')
      } else if (pushContentBean?.isFinanceProduct()) {
        this.productPrice = pushContentBean.yield ?? ''
        this.hotEffectIcon = $r('app.media.plvlw_product_push_hot_effect_icon_finance')
        this.hotEffectText = $r('app.string.plvlw_product_push_hot_effect_text_finance')
      } else if (pushContentBean?.isPositionProduct()) {
        this.productPrice = pushContentBean.getTreatment() ?? ''
        this.hotEffectIcon = $r('app.media.plvlw_product_push_hot_effect_icon_job')
        this.hotEffectText = $r('app.string.plvlw_product_push_hot_effect_text_job')
      }
      this.productBuyText = pushContentBean?.btnShow ?? $r('app.string.plvlw_commodity_buy')
      this.hotEffectEnable = productDataBean.hotEffectEnable ?? false
      this.hotEffectClickTimes = productDataBean.hotEffectClickTimes ?? 0
      this.hotEffectClickTimesText = productDataBean.getHotEffectClickTimes() ?? ''
    }).pushTo(this.observers)
  }

  build() {
    Column() {
      if (this.hotEffectEnable) {
        Row() {
          Image(this.hotEffectIcon)
            .width(16)
            .height(16)
            .margin({
              left: 2
            })

          Text(this.hotEffectText)
            .fontSize(12)
            .fontColor('#FFFFFF')
            .margin({
              left: 1
            })

          if (this.hotEffectClickTimes > 1) {
            Text('x')
              .fontSize(10)
              .fontColor('#FFFFFF')
              .margin({
                left: 4
              })

            Text(this.hotEffectClickTimesText)
              .fontSize(15)
              .fontColor('#FFFFFF')
          }
        }
        .id('plvlw_product_push_hot_effect_layout')
        .width(PLVCommonConstants.FULL_PERCENT)
        .height(24)
        .borderRadius(20)
        .linearGradient({
          angle: 90,
          colors: [
            ['#ffFFAF0F', 0],
            ['#ccFFAF0F', 0.72],
            ['#00FFAF0F', 1]
          ]
        })

        Blank().height(8)
      }

      RelativeContainer() {
        Image($r('app.media.plvlw_product_push_card_background_icon'))
          .width(52)
          .height(51)
          .alignRules({
            bottom: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Bottom },
            right: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.End }
          })
          .margin({
            bottom: 12
          })

        RelativeContainer() {
          Image(this.productCover)
            .width(PLVCommonConstants.FULL_PERCENT)
            .height(PLVCommonConstants.FULL_PERCENT)

          Text(this.productIndex)
            .fontSize(12)
            .fontColor($r('app.color.plvlw_product_push_card_index_text'))
            .fontWeight(FontWeight.Bold)
            .padding({
              left: 6,
              right: 6,
              top: 2,
              bottom: 2
            })
            .backgroundColor($r('app.color.plvlw_product_push_card_index_background'))
            .borderRadius({
              bottomRight: 6
            })
            .alignRules({
              top: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Top },
              left: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.Start }
            })

          if (this.productTag) {
            Text(this.productTag)
              .fontSize(10)
              .fontColor($r('app.color.plvlw_product_push_card_tag_text_with_image'))
              .backgroundColor($r('app.color.plvlw_product_push_card_tag_background_with_image'))
              .padding({
                left: 4,
                right: 4,
                top: 1,
                bottom: 1
              })
              .borderRadius(2)
              .alignRules({
                bottom: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Bottom },
                left: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.Start }
              })
              .margin({
                left: 3,
                bottom: 3
              })
          }
        }
        .id('plvlw_product_push_image_layout')
        .width(PLVCommonConstants.FULL_PERCENT)
        .aspectRatio(1)
        .margin(2)
        .alignRules({
          top: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Top },
          middle: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.Center }
        })
        .borderRadius(4)
        .clip(true)

        Text(this.productName)
          .id('plvlw_product_push_name_tv')
          .width(PLVCommonConstants.FULL_PERCENT)
          .fontSize(12)
          .fontColor($r('app.color.plvlw_product_push_card_name'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .ellipsisMode(EllipsisMode.END)
          .alignRules({
            top: { anchor: 'plvlw_product_push_image_layout', align: VerticalAlign.Bottom }
          })
          .margin({
            top: 2,
            left: 4,
            right: 4
          })

        Text() {
          Span(this.productPrice)

          if (!this.productPriceOpened) {
            Span(' ')
            Span($r('app.string.plvlw_commodity_price_not_opened'))
              .fontColor('#999999')
          }
        }
        .id('plvlw_product_push_price_tv')
        .width(PLVCommonConstants.FULL_PERCENT)
        .fontSize(12)
        .fontColor($r('app.color.plvlw_product_push_card_price'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .ellipsisMode(EllipsisMode.END)
        .alignRules({
          top: { anchor: 'plvlw_product_push_name_tv', align: VerticalAlign.Bottom }
        })
        .margin({
          left: 4,
          right: 4
        })

        Text(this.productBuyText)
          .id('plvlw_product_push_buy_action_tv')
          .height(24)
          .fontSize(12)
          .fontColor($r('app.color.plvlw_product_push_card_buy_action_text'))
          .textAlign(TextAlign.Center)
          .backgroundColor($r('app.color.plvlw_product_push_card_buy_action_background'))
          .borderRadius(4)
          .alignRules({
            top: { anchor: 'plvlw_product_push_price_tv', align: VerticalAlign.Bottom },
            left: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.Start },
            right: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.End }
          })
          .margin({
            left: 4,
            right: 4,
            top: 6
          })
          .opacity(this.productPriceOpened ? 1 : 0.6)
          .onClick(() => {
            this.onClickProduct()
          })

        Image($r('app.media.plvlw_product_push_close_icon'))
          .id('plvlw_product_push_close_iv')
          .width(20)
          .height(20)
          .alignRules({
            top: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Top },
            right: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.End }
          })
          .margin({
            top: 2
          })
          .onClick(() => {
            this.onCloseProduct()
          })
      }
      .id('plvlw_product_push_card')
      .width(PLVCommonConstants.FULL_PERCENT)
      .height(172)
      .backgroundColor($r('app.color.plvlw_product_push_card_layout_background_with_image'))
      .borderRadius(6)
    }
    .width(104)
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
  }
}

@Component
struct NoImageProductCard {
  productDataBean: PLVState<PLVProductDataBean> = lateInit()
  onClickProduct: () => void = lateInit()
  onCloseProduct: () => void = lateInit()
  @State private hotEffectEnable: boolean = false
  @State private hotEffectClickTimes: number = 0
  @State private hotEffectClickTimesText: string = ''
  @State private hotEffectIcon: Resource = $r('app.media.plvlw_product_push_hot_effect_icon_normal')
  @State private hotEffectText: ResourceStr = $r('app.string.plvlw_product_push_hot_effect_text_normal')
  @State private productIndex: string = ''
  @State private productTag: string | undefined = undefined
  @State private productName: string = ''
  @State private productPrice: ResourceStr = ''
  @State private productPriceOpened: boolean = true
  @State private productBuyText: ResourceStr = $r('app.string.plvlw_commodity_buy')
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    this.productDataBean.observe(productDataBean => {
      const pushContentBean = productDataBean.pushContentBean
      this.productIndex = pushContentBean?.showId?.toString() ?? ''
      this.productTag = pushContentBean?.getParsedFeatures()?.[0]
      this.productName = pushContentBean?.name ?? ''
      if (pushContentBean?.isNormalProduct()) {
        this.productPriceOpened = pushContentBean.isPriceOpened()
        if (!this.productPriceOpened) {
          this.productPrice = `¥??`
        } else if (pushContentBean.customPrice) {
          this.productPrice = pushContentBean.customPrice
        } else if (pushContentBean.isFreeForPay()) {
          this.productPrice = $r('app.string.plvlw_commodity_free')
        } else {
          this.productPrice = `¥${pushContentBean.realPrice}`
        }
        this.hotEffectIcon = $r('app.media.plvlw_product_push_hot_effect_icon_normal')
        this.hotEffectText = $r('app.string.plvlw_product_push_hot_effect_text_normal')
      } else if (pushContentBean?.isFinanceProduct()) {
        this.productPrice = pushContentBean.yield ?? ''
        this.hotEffectIcon = $r('app.media.plvlw_product_push_hot_effect_icon_finance')
        this.hotEffectText = $r('app.string.plvlw_product_push_hot_effect_text_finance')
      } else if (pushContentBean?.isPositionProduct()) {
        this.productPrice = pushContentBean.getTreatment() ?? ''
        this.hotEffectIcon = $r('app.media.plvlw_product_push_hot_effect_icon_job')
        this.hotEffectText = $r('app.string.plvlw_product_push_hot_effect_text_job')
      }
      this.productBuyText = pushContentBean?.btnShow ?? $r('app.string.plvlw_commodity_buy')
      this.hotEffectEnable = productDataBean.hotEffectEnable ?? false
      this.hotEffectClickTimes = productDataBean.hotEffectClickTimes ?? 0
      this.hotEffectClickTimesText = productDataBean.getHotEffectClickTimes() ?? ''
    }).pushTo(this.observers)
  }

  build() {
    Column() {
      if (this.hotEffectEnable) {
        Row() {
          Image(this.hotEffectIcon)
            .width(16)
            .height(16)
            .margin({
              left: 2
            })

          Text(this.hotEffectText)
            .fontSize(12)
            .fontColor('#FFFFFF')
            .margin({
              left: 1
            })

          if (this.hotEffectClickTimes > 1) {
            Text('x')
              .fontSize(10)
              .fontColor('#FFFFFF')
              .margin({
                left: 4
              })

            Text(this.hotEffectClickTimesText)
              .fontSize(15)
              .fontColor('#FFFFFF')
          }
        }
        .id('plvlw_product_push_hot_effect_layout')
        .width(PLVCommonConstants.FULL_PERCENT)
        .height(24)
        .borderRadius(20)
        .linearGradient({
          angle: 90,
          colors: [
            ['#ffFFAF0F', 0],
            ['#ccFFAF0F', 0.72],
            ['#00FFAF0F', 1]
          ]
        })

        Blank().height(8)
      }

      RelativeContainer() {

        Text(this.productIndex)
          .fontSize(12)
          .fontColor($r('app.color.plvlw_product_push_card_index_text'))
          .fontWeight(FontWeight.Bold)
          .alignRules({
            top: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Top },
            left: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.Start }
          })
          .margin({
            top: 4,
            left: 8
          })

        RelativeContainer() {
          Image($r('app.media.plvlw_product_push_card_background_icon'))
            .width(52)
            .height(51)
            .alignRules({
              bottom: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Bottom },
              right: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.End }
            })
            .margin({
              bottom: 12
            })

          Text(this.productTag)
            .id('plvlw_product_push_tag_tv')
            .fontSize(10)
            .fontColor($r('app.color.plvlw_product_push_card_tag_text_no_image'))
            .borderColor($r('app.color.plvlw_product_push_card_tag_background_stroke_no_image'))
            .borderRadius(2)
            .borderWidth(1)
            .padding({
              left: 4,
              right: 4,
              top: 1,
              bottom: 1
            })
            .alignRules({
              top: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Top },
              left: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.Start }
            })
            .margin({
              left: 4,
              top: 8
            })
            .visibility(this.productTag ? Visibility.Visible : Visibility.None)

          Text(this.productName)
            .id('plvlw_product_push_name_tv')
            .width(PLVCommonConstants.FULL_PERCENT)
            .fontSize(12)
            .fontColor($r('app.color.plvlw_product_push_card_name'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .ellipsisMode(EllipsisMode.END)
            .alignRules({
              top: { anchor: 'plvlw_product_push_tag_tv', align: VerticalAlign.Bottom }
            })
            .margin({
              top: 6,
              left: 4,
              right: 4
            })

          Text() {
            Span(this.productPrice)

            if (!this.productPriceOpened) {
              Span(' ')
              Span($r('app.string.plvlw_commodity_price_not_opened'))
                .fontColor('#999999')
            }
          }
          .id('plvlw_product_push_price_tv')
          .width(PLVCommonConstants.FULL_PERCENT)
          .fontSize(12)
          .fontColor($r('app.color.plvlw_product_push_card_price'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .ellipsisMode(EllipsisMode.END)
          .alignRules({
            top: { anchor: 'plvlw_product_push_name_tv', align: VerticalAlign.Bottom }
          })
          .margin({
            left: 4,
            right: 4
          })

          Text(this.productBuyText)
            .id('plvlw_product_push_buy_action_tv')
            .height(24)
            .fontSize(12)
            .fontColor($r('app.color.plvlw_product_push_card_buy_action_text'))
            .textAlign(TextAlign.Center)
            .backgroundColor($r('app.color.plvlw_product_push_card_buy_action_background'))
            .borderRadius(4)
            .alignRules({
              bottom: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Bottom },
              left: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.Start },
              right: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.End }
            })
            .margin({
              left: 4,
              right: 4,
              bottom: 4
            })
            .opacity(this.productPriceOpened ? 1 : 0.6)
            .onClick(() => {
              this.onClickProduct()
            })
        }
        .width(PLVCommonConstants.FULL_PERCENT)
        .backgroundColor($r('app.color.plvlw_product_push_card_layout_background_inner_no_image'))
        .borderRadius(6)
        .alignRules({
          top: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Top }
        })
        .margin({
          top: 24
        })

        Image($r('app.media.plvlw_product_push_close_icon'))
          .id('plvlw_product_push_close_iv')
          .width(20)
          .height(20)
          .alignRules({
            top: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Top },
            right: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.End }
          })
          .margin({
            top: 2
          })
          .onClick(() => {
            this.onCloseProduct()
          })
      }
      .id('plvlw_product_push_card')
      .width(PLVCommonConstants.FULL_PERCENT)
      .height(122)
      .backgroundColor($r('app.color.plvlw_product_push_card_layout_background_outer_no_image'))
      .borderRadius(6)
    }
    .width(104)
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
  }
}