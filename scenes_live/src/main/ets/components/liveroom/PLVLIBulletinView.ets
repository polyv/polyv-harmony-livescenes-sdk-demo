import { PLVWebUtils } from '@polyvharmony/live-scenes-sdk'

@Preview
@Component
export struct PLVLIBulletinView {
  @Link @Watch('onBulletinSrc') bulletinSrc: string | undefined
  @State propBulletinSrc: string | undefined = this.bulletinSrc
  @State layoutHeightScaleY: number = 0
  appearTimerId?: number

  build() {
    if (this.propBulletinSrc) {
      Row() {
        Text() {
          ImageSpan($r('app.media.plvli_gonggao'))
            .width(12)
            .height(12)
            .margin({ right: 6 })
            .verticalAlign(ImageSpanAlignment.CENTER)
          Span($r('app.string.plvli_live_bulletin_tip'))
            .fontSize(12)
            .fontColor('#ffffff')
        }

        Text(this.propBulletinSrc)
          .fontSize(12)
          .fontColor('#ffffff')
          .constraintSize({ maxWidth: '75%' })
          .textOverflow({ overflow: TextOverflow.MARQUEE })
      }
      .onAppear(() => {
        animateTo({ duration: 200, curve: Curve.Linear }, () => {
          this.layoutHeightScaleY = 1
        })
        this.appearTimerId = setTimeout(() => {
          animateTo({
            duration: 200, curve: Curve.Linear, onFinish: () => {
              this.propBulletinSrc = undefined
            }
          }, () => {
            this.layoutHeightScaleY = 0
          })
        }, 2000 + (this.propBulletinSrc?.length || 0) * 80)
      })
      .onDisAppear(() => {
        this.layoutHeightScaleY = 0
        clearTimeout(this.appearTimerId)
      })
      .padding({ left: 10, right: 10 })
      .backgroundColor('#B30181FF')
      .alignItems(VerticalAlign.Center)
      .height(24)
      .scale({ y: this.layoutHeightScaleY })
      .borderRadius(12)
    }
  }

  onBulletinSrc() {
    this.propBulletinSrc = PLVWebUtils.cleanHTML(this.bulletinSrc || '')
  }
}