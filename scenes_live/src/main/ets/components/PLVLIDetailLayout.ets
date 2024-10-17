import { IPLVBackwardInterface, PLVCallback, PLVChannelData, PLVCommonConstants, PLVDeviceUtils, PLVSimpleWeb, PLVWebController, PLVWebUtils } from '@polyvharmony/live-scenes-sdk'

const TAG = '[PLVLIDetailLayout]'

@Preview
@Component
export struct PLVLIDetailLayout {
  @LocalStorageLink('channelData') channelData?: PLVChannelData = undefined
  @Link layoutController: PLVDetailLayoutController
  @Link @Watch('onBulletinSrc') bulletinSrc: string | undefined
  @State introSrc: string | undefined = this.channelData?.getMenuDescContent()

  aboutToAppear(): void {
    this.initData()
  }

  build() {
    Column() {
      Scroll() {
        Column() {
          Blank(60)
          if (this.bulletinSrc) {
            Column() {
              Text() {
                ImageSpan($r('app.media.plvli_detail_gonggao'))
                  .width(16)
                  .height(16)
                  .margin({ right: 8 })
                  .verticalAlign(ImageSpanAlignment.CENTER)
                Span($r('app.string.plvli_live_bulletin'))
                  .fontSize(16)
              }
              .width(PLVCommonConstants.FULL_PERCENT)
              .textAlign(TextAlign.Start)

              PLVSimpleWeb({ controller: this.layoutController.bulletinWebController, src: '' })
                .height(216)
                .margin({ top: 16 })
            }
            .backgroundColor('#CCF3F3F3')
            .borderRadius(10)
            .padding(16)
          }

          Column() {
            Text() {
              ImageSpan($r('app.media.plvli_intro'))
                .width(16)
                .height(16)
                .margin({ right: 8 })
                .verticalAlign(ImageSpanAlignment.CENTER)
              Span($r('app.string.plvli_live_intro'))
                .fontSize(16)
            }
            .width(PLVCommonConstants.FULL_PERCENT)
            .textAlign(TextAlign.Start)

            if (this.introSrc) {
              PLVSimpleWeb({ controller: this.layoutController.introWebController, src: '' })
                .margin({ top: 16 })
            } else {
              Text($r('app.string.plvli_live_no_intro'))
                .width(PLVCommonConstants.FULL_PERCENT)
                .layoutWeight(1)
                .offset({ y: -8 })
                .textAlign(TextAlign.Center)
                .fontSize(14)
            }
          }
          .constraintSize({ minHeight: 216, maxHeight: 400 })
          .margin({ top: 8 })
          .backgroundColor('#CCF3F3F3')
          .borderRadius(10)
          .padding(16)
        }
        .width(PLVCommonConstants.FULL_PERCENT)
      }
      .scrollable(ScrollDirection.Vertical)
      .scrollBar(BarState.Off)
      .width(PLVCommonConstants.FULL_PERCENT)
      .height(400)
    }
    .padding({
      left: 16,
      right: 16,
      top: 6,
      bottom: 6 + PLVDeviceUtils.getNavigationIndicatorHeight()
    })
    .justifyContent(FlexAlign.End)
    .width(PLVCommonConstants.FULL_PERCENT)
    .height(PLVCommonConstants.FULL_PERCENT)
  }

  initData() {
    this.layoutController.introSrc = this.introSrc
    this.layoutController.bulletinSrc = this.bulletinSrc
  }

  onBulletinSrc() {
    this.layoutController.bulletinSrc = this.bulletinSrc
  }
}

export class PLVDetailLayoutController implements IPLVBackwardInterface {
  bulletinSrc: string | undefined
  introSrc: string | undefined
  isLayoutShow?: boolean
  introWebController = new PLVWebController()
    .nestedScrollOptions({
      scrollForward: NestedScrollMode.PARALLEL,
      scrollBackward: NestedScrollMode.SELF_FIRST
    })
    .onControllerAttached(() => {
      this.introWebController.loadHtmlData(PLVWebUtils.toWebViewContent(this.introSrc))
    })
  bulletinWebController = new PLVWebController()
    .onControllerAttached(() => {
      this.bulletinWebController.loadHtmlData(PLVWebUtils.toWebViewContent(this.bulletinSrc))
    })
  accessBackward: PLVCallback<void, boolean> = () => {
    if (this.isLayoutShow && (this.bulletinWebController.accessBackward() || this.introWebController.accessBackward())) {
      return true
    }
    return false
  }
  backward: PLVCallback<void, void> = () => {
    if (this.bulletinWebController.accessBackward()) {
      this.bulletinWebController.backward()
    } else if (this.introWebController.accessBackward()) {
      this.introWebController.backward()
    }
  }
}