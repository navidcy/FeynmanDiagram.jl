# Evaluation of counterterms

For illustrative simplicity, let us consider the renormalization of the chemical potential and Yukawa effective mass in the uniform electron gas (UEG). Following the Negele & Orland conventions, the non-interacting Green's function $g$ is given by

```math
 g(\mathbf{k}, i\omega_n) = -\frac{1}{i\omega_n-\epsilon_\mathbf{k} + \mu},
```

where $G$ is the bold Green's function, $\omega_n = 2\pi (n+1)/\beta$ is a fermionic Matsubara frequency, and $\mu$ is the exact chemical potential derived from the interacting density $n$. The 1PI self-energy $\Sigma$ is then defined through the following Dyson equation:

```math
 G^{-1} = g^{-1} + \Sigma \implies G = g - g\Sigma g + g\Sigma g \Sigma g - ...\;.
```

Following the variational diagrammatic Monte-Carlo (VDMC) approach, we rewrite the bare Green's function $g$ in terms of a renormalized propagator $g_R$, writing

```math
 g(\mathbf{k}, i\omega_n) = -\frac{1}{i\omega_n-\epsilon_\mathbf{k} + \mu_R + \delta\mu}
```

where, motivated by Luttinger's theorem, the renormalized chemical potential $\mu_R = \mu - \delta\mu \equiv \epsilon_F = k^2_F / 2 m$ is chosen so as to preserve the non-interacting Fermi surface, whereas $\lambda$ is taken as a fixed, non-zero constant.

Similarly, the Coulomb interaction is re-written as

```math
 V(q) = \frac{e^2}{\epsilon_0 q^2} = \frac{e^2}{\epsilon_0} \frac{1}{q^2 + \lambda + \delta\lambda}.
```

We then work perturbatively in terms of the following renormalized Green's function and interaction,

```math
\begin{aligned}
 g_R(k, i\omega_n) &\equiv -\frac{1}{i\omega_n-\epsilon_k + \mu_R} = g(k, i\omega_n) \Big|_{\delta\mu = 0},\\[2ex]
 V_\lambda(q) &\equiv \frac{e^2}{\epsilon_0} \frac{1}{q^2 + \lambda} = V(q) \Big|_{\delta\lambda = 0}.
\end{aligned}
```

## New approach to counterterm evaluation

In the NEFT codebase, the counterterms are generated by directly differentiating diagrams in the perturbative series for a given observable, which allows for a flexible and generic reformulation of the VDMC algorithm. This is made possible by representing all diagrams by differentiable expression trees. In contrast, in the original VDMC approach one first Taylor expands all propagators $g[g_R]$ and $V[V_\lambda]$ entering a given observable by hand and collects terms in orders of $\xi$ manually prior to integration.

The $\mathcal{O}(\xi^N)$ counterterms in RPT with $n$ and $m$ chemical potential / interaction derivatives are given by

```math
 (\delta\mu)^n (\delta\lambda)^m \times \frac{1}{n! m!}\partial^n_{\mu} \partial^m_\lambda D_{N - n - m},
```

where $D$ is the sum of all Feynman diagrams at the appropriate loop order $N - n - m$. The renormalization is performed in post-processing by multiplying with the Taylor series for $(\delta\mu)^n (\delta\lambda)^m$ in $\xi$ and collecting terms $\propto \xi^N$. The chemical potential shift $\delta \mu_n$ is derived from a separate MC simulation of $\Sigma^{\lambda_R}_F(k_F, ik_0)$.

To demonstrate that the two approaches outlined above are equivalent, it is sufficient to consider separately the cases of $V$ and $g$ raised to an arbitrary power in the Matsubara representation; we will omit the coordinates for brevity.

First, consider the chemical potential counterterms. Let $\delta\mu \equiv \mu_0 - \mu_R$. Taylor expanding $g[g_R]$ about $\delta\mu = 0$, we have

```math
 g = \frac{g_R}{1 - g_R\delta\mu} = g_R\sum^\infty_{n=0} (g_R\delta\mu)^n = \sum^\infty_{n=0} \frac{(\delta\mu)^n}{n!} \partial^n_\mu g_R,
```

since

```math
 g^{n+1}_R = \frac{1}{n!} \partial^n_\mu g_R.
```

Then,

```math
\begin{aligned}
 g^m & = \left(\sum^\infty_{n=0} \frac{(\delta\mu)^n}{n!} \partial^n_\mu g_R\right)^m = g^m_R\left(1 - g_R\delta\mu\right)^{-m} = g^m_R \sum^\infty_{n=0} \binom{m+n-1}{n} (g_R\delta\mu)^{n}\\
     & = \sum^\infty_{n=0} (\delta\mu)^{n} \frac{(m+n-1)!}{n! (m-1)!} g^{m+n}_R = \sum^\infty_{n=0} \frac{(\delta\mu)^{n}}{n! (m-1)!} \partial^{m+n-1}_\mu g_R = \sum^\infty_{n=0} \frac{(\delta\mu)^{n}}{n!} \partial^{n}_\mu g^m_R,
\end{aligned}
```

where in the last step, we replaced

```math
\begin{aligned}
 \frac{1}{(m-1)!} \partial^{m-1}_\mu g_R = g^m_R.
\end{aligned}
```

Thus, the series for $g^m$ may be represented either by expanding each $g[g_R]$ by hand and collecting terms, or by a direct Taylor expansion of $g^m$ about $\delta\mu = 0$.

It remains to show that these two strategies are also equivalent for the expansion of $V^m$. Let $\delta\lambda \equiv \lambda_0 - \lambda_R = -\lambda_R$ and Taylor expand $V[V_\lambda]$ about $\delta\lambda = 0$—we obtain

```math
%
%  V = \frac{V_ \lambda}{1 - \frac{\lambda}{q^2 + \lambda}} = V_\lambda \sum_{n=0}^{\infty} \left(\frac{\lambda}{q^2 + \lambda}\right)^n = V_\lambda \sum_{n=0}^{\infty} \left(V_\lambda \delta\lambda\right)^n = \sum^\infty_{n=0} \frac{(-\lambda)^n}{n!} \partial^n_\lambda V_\lambda,
%
```

```math
 V = \frac{V_ \lambda}{1 - \delta_\lambda} = V_\lambda \sum_{n=0}^{\infty} \delta^n_\lambda = \sum^\infty_{n=0} \frac{(\delta\lambda)^n}{n!} \partial^n_\lambda V_\lambda
```

where

```math
 \delta_\lambda \equiv \frac{\lambda}{q^2 + \lambda},
```

since

```math
\begin{aligned}
 \frac{(\delta\lambda)^{n}}{n!} \partial^{n}_\lambda V_\lambda = 8\pi\frac{(-\lambda)^{n}}{n!} \partial^{n}_\lambda \left(\frac{1}{q^2 + \lambda}\right) = \frac{8\pi\lambda^n}{(q^2 + \lambda)^{n+1}} = V_\lambda \delta^n_\lambda.
\end{aligned}
```

We also have that

```math
\begin{aligned}
 \frac{(\delta\lambda)^n}{n!} \partial^{n}_\lambda V^m_\lambda = \left(\frac{\lambda}{8\pi}\right)^n \frac{m^{(n)}}{n!} V^{m+n}_\lambda = \binom{m + n - 1}{n} V^m_\lambda \delta^n_\lambda,
\end{aligned}
```

where $m^{(n)} = \prod_{i=0}^{n-1} (m + i)$ is a rising factorial and

```math
 \binom{m + n - 1}{n} = \frac{(m + n - 1)!}{n! (m-1)!} = \frac{m^{(n)}}{n!}.
```

Thus,

```math
\begin{aligned}
 V^m & = \left(\sum^\infty_{n=0} \frac{(\delta\lambda)^n}{n!} \partial^n_\lambda V_\lambda\right)^m = V^m_\lambda \left(1 - \delta_\lambda\right)^{-m} = \sum^\infty_{n=0} \binom{m+n-1}{n} V^m_\lambda \delta^n_\lambda = \sum^\infty_{n=0} \frac{(\delta\lambda)^{n}}{n!} \partial^{n}_\lambda V^m_\lambda.
\end{aligned}
```

Since the order of differentiation w.r.t. $\mu$ and $\lambda$ does not matter, it follows that a general diagram $\mathcal{D}[g, V] \sim g^n V^m$ may be represented either by pre-expanding $g[g_\mu]$ and $V[V_\lambda]$ and collecting terms, or by directly evaluating terms in the Taylor series for $\mathcal{D}[g_\mu, V_\lambda]$; this codebase uses the latter approach.

## Evaluation of interaction counterterms

An example of the interaction counterterm evaluation for a diagram with $n_\lambda = 3$ and $m$ interaction lines. Since the Julia implementation evaluates the interaction counterterms of a given diagram as $\frac{(-\lambda)^n}{n!}\partial^n_\lambda V^m_\lambda$, we pick up an extra factor of $l!$ on each $l$th-order derivative in the chain rule.

![An example of the representation of interaction counterterm diagrams via differentiation.](../../assets/derivative_example.svg#derivative_example)

## Benchmark of counterterms in the UEG

As a concrete example, we have evaluated the individual diagrams and associated counterterms entering the RPT series for the total density $n[g_\mu, V_\lambda]$ in units of the non-interacting density $n_0$. The diagrams/counterterms are denoted by partitions $\mathcal{P} \equiv (n_{\text{loop}}, n_\mu, n_\lambda)$ indicating the total loop order and number of $\mu$ and $\lambda$ derivatives.

### 3D UEG

For this benchmark, we take $r_s = 1$, $\beta = 40 \epsilon_F$, and $\lambda = 0.6$. All partitions contributing up to 4th order are included, as well as some selected partitions at 5th and 6th order.

| $(n_{\text{loop}}, n_\lambda, n_\mu)$ | $n / n_0$ |
| :---: | :---: |
| (1, 0, 1) |     0.40814(16)    |
| (1, 0, 2) |     0.02778(21)    |
| (1, 0, 3) |    -0.00096(60)    |
| (2, 0, 0) |     0.28853(12)    |
| (2, 1, 0) |     0.07225(3)     |
| (2, 2, 0) |     0.02965(2)     |
| (2, 0, 1) |     0.09774(30)    |
| (2, 1, 1) |     0.01594(10)    |
| (2, 0, 2) |     0.00240(130)   |
| (3, 0, 0) |     0.10027(37)    |
| (3, 1, 0) |     0.04251(21)    |
| (3, 0, 1) |     0.02600(150)   |
| (4, 0, 0) |     0.00320(130)   |
| (2, 1, 2) |    -0.00111(18)    |
| (2, 0, 3) |    -0.00430(150)   |
| (3, 2, 0) |     0.02241(8)     |
| (3, 3, 0) |     0.01429(7)     |