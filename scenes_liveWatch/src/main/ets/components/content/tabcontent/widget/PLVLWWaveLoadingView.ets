@Preview
@Component
export struct PLVLWWaveLoadingView {
  @State viewColor: ResourceColor = $r('app.color.plvlw_function_color_red')
  @State viewPadding: number = 2
  @State itemCount: number = 3
  @State viewWidth: number = 12
  @State viewHeight: number = 12
  @State itemWidth: number = 1.2
  @State private heightAni: number = 1

  build() {
    Row({ space: (this.viewWidth - this.viewPadding * 2 - this.itemCount * this.itemWidth) / (this.itemCount - 1) }) {
      ForEach(Array(this.itemCount).fill(1), (item: number, index) => {
        Stack()
          .backgroundColor(this.viewColor)
          .height(index % 2 == 0 ? this.heightAni * (this.viewHeight - this.viewPadding * 2) : (1 - this.heightAni + 0.3) * (this.viewHeight - this.viewPadding * 2))
          .width(this.itemWidth)
          .borderRadius(this.itemWidth)
      })
    }
    .alignItems(VerticalAlign.Bottom)
    .padding(this.viewPadding)
    .width(this.viewWidth)
    .height(this.viewHeight)
    .onAppear(() => {
      animateTo({
        duration: 1000,
        curve: Curve.Linear,
        iterations: -1,
        playMode: PlayMode.Alternate
      }, () => {
        this.heightAni = 0.3
      })
    })
  }
}
