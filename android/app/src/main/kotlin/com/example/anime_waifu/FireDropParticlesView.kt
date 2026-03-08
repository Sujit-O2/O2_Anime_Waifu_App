package com.example.anime_waifu

import android.content.Context
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.util.AttributeSet
import android.view.View
import kotlin.math.cos
import kotlin.math.sin
import kotlin.random.Random

class FireDropParticlesView @JvmOverloads constructor(
    context: Context, attrs: AttributeSet? = null, defStyleAttr: Int = 0
) : View(context, attrs, defStyleAttr) {

    private class Particle {
        var x = 0f
        var y = 0f
        var vx = 0f
        var vy = 0f
        var radius = 0f
        var life = 0f
        var maxLife = 0f
        var color = Color.WHITE
    }

    private val particles = mutableListOf<Particle>()
    private val maxParticles = 40
    private val paint = Paint(Paint.ANTI_ALIAS_FLAG)
    private var lastTime = System.currentTimeMillis()

    private val colors = intArrayOf(
        Color.parseColor("#FFFF6D00"), // Orange
        Color.parseColor("#FFFF3D00"), // Deep Orange
        Color.parseColor("#FFFFD600"), // Yellow
        Color.parseColor("#FFD50000")  // Red
    )

    init {
        paint.style = Paint.Style.FILL
    }

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)
        val now = System.currentTimeMillis()
        val dt = (now - lastTime) / 1000f
        lastTime = now

        // Emit new particles
        if (particles.size < maxParticles && Random.nextFloat() < 0.2f) {
            particles.add(Particle().apply {
                x = Random.nextFloat() * width
                y = height.toFloat() // start from bottom or near bottom
                vx = (Random.nextFloat() - 0.5f) * width * 0.1f // slight horizontal drift
                vy = -Random.nextFloat() * height * 0.3f - 100f // moving UP like fire
                radius = Random.nextFloat() * 12f + 4f
                maxLife = Random.nextFloat() * 2f + 1f
                life = maxLife
                color = colors[Random.nextInt(colors.size)]
            })
        }

        val iterator = particles.iterator()
        while (iterator.hasNext()) {
            val p = iterator.next()
            p.x += p.vx * dt
            p.y += p.vy * dt
            p.life -= dt
            
            p.vx += (Random.nextFloat() - 0.5f) * 20f

            if (p.life <= 0 || p.y < -p.radius * 2 || p.x < 0 || p.x > width) {
                iterator.remove()
                continue
            }

            // Fade out as it dies
            val alpha = ((p.life / p.maxLife) * 255).toInt().coerceIn(0, 255)
            paint.color = p.color
            paint.alpha = (alpha * 0.6f).toInt() // max 60% opacity
            
            // Draw glow
            paint.setShadowLayer(p.radius * 1.5f, 0f, 0f, p.color)
            canvas.drawCircle(p.x, p.y, p.radius, paint)
            paint.clearShadowLayer()
        }

        postInvalidateOnAnimation()
    }

    override fun onAttachedToWindow() {
        super.onAttachedToWindow()
        lastTime = System.currentTimeMillis()
        postInvalidate()
    }
}
